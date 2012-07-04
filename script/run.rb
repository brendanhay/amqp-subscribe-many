#!/usr/bin/env ruby

require "rubygems"
require "bundler"

Bundler.setup(:default)

$:.unshift(File.dirname(__FILE__) + "/../lib")

require "messaging"

LOCALHOST = "amqp://localhost"
EXCHANGE  = "exchange"
TYPE      = "direct"
QUEUE     = "queue"
KEY       = "key"

config = YAML::load_file(File.dirname(__FILE__) + "/config.yml")

EventMachine.run do
  # Consume
  consumer = Messaging::Consumer.new(config["consume_from"])

  consumer.subscribe(EXCHANGE, TYPE, QUEUE, KEY) do |meta, payload|
    meta.ack
  end

  # Publish
  producer = Messaging::Producer.new(config["publish_to"])

  EventMachine::add_periodic_timer(1) do
    producer.publish(EXCHANGE, TYPE, KEY, "some_random_payload")
  end

  trap("INT") { EventMachine.stop }
end
