bucket_cache_hook
=================

This is a sample post commit hook for Riak that generates an aggregate JSON representation of the contents of a bucket.

Installation
============

The easiest way to install the bucket_cache_hook is to copy it into the root directory of your riak installation and:

	# start riak and compile the bucket_cache_hook.erl
	$ ./bin/riak console
	(riak1@127.0.0.1)1> c(bucket_cache_hook).
	(riak1@127.0.0.1)2> q().

	# then add it as a postcommit hook to your chosen bucket
	$ curl -XPUT -H "Content-Type: application/json" http://127.0.0.1:8098/riak/test -d '{"props":{"postcommit":[{"mod": "bucket_cache_hook", "fun": "create_cache"}]}}'

	# now load a test payload
	$ curl -XPUT -H "Content-Type: applicaiton/json" http://127.0.0.1:8098/riak/test/test.json -d '{ "message": "this is a test" }'
	
	# then check that it loaded
	$ curl http://127.0.0.1:8098/riak/test/test.json
	{ "message": "this is a test" }

	# next  check the cache, you'll find [ {filename : payload } ]
	$ curl http://127.0.0.1:80918/riak/cache/test
	[{"test.json":{"message":"this is a test"}}]

	# then clean up after yourself
	$ curl -XDELETE http://127.0.0.1:8098/riak/test/test.json
	$ curl http://127.0.0.1:8098/riak/cache/test
	[]

David J. Goehrig

