#!/usr/bin/env ruby

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
  consumer = Messaging::Consumer.new([LOCALHOST, LOCALHOST])

  consumer.subscribe(EXCHANGE, QUEUE, KEY) do |meta, payload|
    meta.ack
  end

  # Publish
  producer = Messaging::Producer.new(LOCALHOST)

  EventMachine::add_periodic_timer(1) do
    producer.publish(EXCHANGE, KEY, "some_random_payload")
  end

  trap("INT") { EventMachine.stop }
end
