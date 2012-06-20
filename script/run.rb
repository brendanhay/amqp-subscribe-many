#!/usr/bin/env ruby

# This Source Code Form is subject to the terms of
# the Mozilla Public License, v. 2.0.
# A copy of the MPL can be found in the LICENSE file or
# you can obtain it at http://mozilla.org/MPL/2.0/.
#

require "rubygems"
require "bundler"

Bundler.setup(:default)

$:.unshift(File.dirname(__FILE__) + "/../lib")

require "messaging"

LOCALHOST = "amqp://localhost"
EXCHANGE  = "exchange"
QUEUE     = "queue"
KEY       = "key"

EventMachine.run do
  # Consume
  c = Messaging::Consumer.new([LOCALHOST, LOCALHOST])

  c.subscribe(EXCHANGE, QUEUE, KEY) do |meta, payload|
    meta.ack
  end

  # Publish
  p = Messaging::Producer.new(LOCALHOST)

  EventMachine::add_periodic_timer(1) do
    p.publish(EXCHANGE, KEY, "some_random_payload")
  end

  trap("INT") { EventMachine.stop }
end
