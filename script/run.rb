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

class Processor < Messaging::Base
  subscribe(EXCHANGE, TYPE, QUEUE, KEY)

  def on_message(meta, payload)
    puts "Channel #{meta.channel.id} received payload #{payload.inspect}"
  end
end

EM.run do
  config    = YAML::load_file(File.dirname(__FILE__) + "/config.yml")
  processor = Processor.new(config["publish_to"], config["consume_from"])

  EM::add_periodic_timer(1) do
    5.times { processor.publish(EXCHANGE, TYPE, KEY, "some_random_payload") }
  end

  trap("INT") do
    processor.disconnect { EM.stop }
  end
end
