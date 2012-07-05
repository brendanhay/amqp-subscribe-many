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

# An example processor displaying how to setup subscriptions
# and a message handler
class Processor < Messaging::Base
  subscribe(EXCHANGE, TYPE, QUEUE, KEY)

  def on_message(meta, payload)
    puts "Channel #{meta.channel.id} received payload #{payload.inspect}"
  end
end

class ProcessorM
  include Messaging::ProducerM
  include Messaging::ConsumerM

  subscribe(EXCHANGE, TYPE, QUEUE, KEY)

  def initialize(options)
    @publish_to, @consume_from = options[:publish_to], options[:consume_from]

    super
  end

  def on_message(meta, payload)
    puts "Channel #{meta.channel.id} received payload #{payload.inspect}"
  end
end

EM.run do
  # Load the config
  config = YAML::load_file(File.dirname(__FILE__) + "/config.yml")

  # Instantiate the example processor
  processor = Processor.new(config)

  # Create a handle to the publish timer, to cancel later
  timer = EM.add_periodic_timer(1) do
    # Publish 5 messages at a time
    5.times { processor.publish(EXCHANGE, TYPE, KEY, "some_random_payload") }
  end

  # Handle Ctrl-C interrupt
  trap("INT") do
    puts "Stopping..."

    # Cancel the publisher timer
    EM.cancel_timer(timer)

    # Disconnect the producer/consumer connections
    processor.disconnect

    # Shutdown the EM loop
    EM.add_timer(1) { EM.stop }
  end
end
