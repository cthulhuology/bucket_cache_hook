-module(bucket_cache_hook).
-author({ "David J Goehrig", "dave@dloh.org" }).
-copyright("© 2012 David J. Goehrig").
-export([ create_cache/1 ]).
-vsn("0.0.1").

% the bucket_cache_hook is a Riak post commit hook that will take json objects from a bucket and install into
% a /riak/cache/[bucket] file as an array of elements.  This is useful for when you want to have a prebaked
% JSON representation of all of the objects in a bucket.

create_cache(Object) ->
	{ok, C} = riak:local_client(),							%% instantiate a local client
	Bucket = erlang:iolist_to_binary([riak_object:bucket(Object)]),			%% grab the name of the bucket of the new object
	Key = erlang:iolist_to_binary([riak_object:key(Object)]),
	CacheJSON = case C:get(<<"cache">>,Bucket) of					%% we then grab out of the cache object the bucket's cace 
		{ ok, OldCache } -> riak_object:get_value(OldCache);
		{ error, notfound } -> <<"[]">>;
		{ error, Reason } ->  throw({ error, Reason })				%% can't fix it, something is really wrong!
	end,
	Cache = mochijson2:decode(CacheJSON),						%% and extract the JSON representation of the cache
	NewCacheJSON = case is_deleted(Object) of 
		true -> iolist_to_binary(mochijson2:encode(delete(Cache,Key)));
		false -> update(Cache,Key,Object)
	end,
	NewCache = riak_object:new(<<"cache">>,Bucket,NewCacheJSON,"application/json"),
	C:put(NewCache).								%% install the new cache

is_deleted(Object) ->
	MetaData = riak_object:get_metadata(Object),
	dict:is_key(<<"X-Riak-Deleted">>,MetaData).

delete(Cache,Key) ->
	delete(Cache,Key,[]).
delete([{struct,[{ Key, _ }]} | Tail ], Key,Accumulator) ->
	delete(Tail,Key,Accumulator);
delete([ Head | Tail ], Key, Accumulator) ->
	delete(Tail,Key,[ Head | Accumulator]);
delete([],_Key,Accumulator) ->
	Accumulator.

update(Cache,Key,Object) ->
	ObjectJSON = riak_object:get_value(Object),				%% get the contents of the newly added object
	O = mochijson2:decode(ObjectJSON),					%% and parse the json of the new object
	iolist_to_binary(mochijson2:encode([ { struct,[ { Key, O }]} | delete(Cache,Key) ])).
