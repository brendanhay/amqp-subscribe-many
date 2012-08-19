Publish One, Subscribe Many
===========

[![Build Status](https://secure.travis-ci.org/brendanhay/amqp-subscribe-many.png)](http://travis-ci.org/brendanhay/amqp-subscribe-many)


Table of Contents
-----------------

* [Introduction](#introduction)
* [Testing](#test)
* [Contribute](#contribute)
* [Licence](#licence)


<a name="introduction" />

Introduction
------------

This gem is a _reference implementation_ for a Publish One, Subscribe Many pattern which is in use at [SoundCloud](http://soundcloud.com).

The pattern assumes a single load balanced publish point and multiple direct consumption points as outlined in the follow diagram:

![Publish One, Subscribe Many](https://raw.github.com/brendanhay/amqp-subscribe-many/master/img/amqp-subscribe-many.png)

In this scenario, a worker's single publish connection is load balanced to a broker. The workers have consumer connections to all possible brokers ensuring
that no matter which broker a message ends up on the consumer can receive it.

Exchanges, queues, and bindings need to all be declared upon connection, ensuring that all brokers will converge on the same set of routing information.

Some buzzwor{th,d}y advantages of this setup include:

* Partitioned Load
* Horizontal Scalability
* High Availability (across the logical topology)

Drawbacks:

* More complex client code
* Another hop in the form of the load-balancer
* A node going down, needs to be brought back up to access the messages

A common error is to conflate availability and durability. In this case, they are treated as seperate concerns with the form of availability on offer refering to the ability of all connected clients to get a message from point to point under most conditions.

Durability requires messages to be published as persistent and manual intervention in the case of a node crash to bring the failed node (or disk) back into consumer awareness, to ensure the messages are flushed.

The code in this repository can be used either as a gem available on [rubygems.org](rubygems.org/gems/amqp-subscribe-many) or as a guide to implement the above pattern using the ruby-amqp gem.

See `./examples/run` for usage.


<a name="test" />

Testing
-------

Run all the tests:

```shell
make test
```


<a name="contribute" />

Contribute
----------

For any problems, comments or feedback please create an issue [here on GitHub](github.com/brendanhay/amqp-subscribe-many/issues).


<a name="licence" />

Licence
-------

amqp-subscribe-many is released under the [Mozilla Public License Version 2.0](http://www.mozilla.org/MPL/)