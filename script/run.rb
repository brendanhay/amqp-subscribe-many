#!/usr/bin/env ruby

require "rubygems"
require "bundler"

Bundler.setup(:default)

$:.unshift(File.dirname(__FILE__) + "/../lib")

require "messaging"

EXCHANGE = "exchange"
TYPE     = "direct"
QUEUE    = "queue"
KEY      = "key"

# Load the config
yml = YAML::load_file(File.dirname(__FILE__) + "/config.yml")

# Setup configuration
Messaging::Configuration.setup do |config|
  config.publish_to   = yml[:publish_to]
  config.consume_from = yml[:consume_from]
end

# Consume example
class ConsumerProcessor
  include Messaging::Consumer

  subscribe(EXCHANGE, TYPE, QUEUE, KEY)

  def on_message(meta, payload)
    log.info("ConsumeProcessor channel #{meta.channel.id} received payload #{payload.inspect}")
  end
end

# Publish example
class ProducerProcessor
  include Messaging::Producer
end

# Consume + publish example
class DuplexProcessor
  include Messaging::Producer
  include Messaging::Consumer

  subscribe(EXCHANGE, TYPE, QUEUE, KEY)

  def on_message(meta, payload)
    log.info("DuplexProcessor channel #{meta.channel.id} received payload #{payload.inspect}")
  end
end

EM.run do

  # Instantiate the processors
  consumer = ConsumerProcessor.new
  producer = ProducerProcessor.new
  duplex   = DuplexProcessor.new

  # Start the consumers
  consumer.consume
  duplex.consume

  # Create a handle to the publish timer, to cancel later
  timer = EM.add_periodic_timer(0.5) do
    producer.publish(EXCHANGE, TYPE, KEY, "a_producer_payload")
    duplex.publish(EXCHANGE, TYPE, KEY, "a_duplex_payload")
  end

  # Handle Ctrl-C interrupt
  trap("INT") do
    puts "Stopping..."

    # Cancel the publisher timer
    EM.cancel_timer(timer)

    # Disconnect the producer/consumer connections
    consumer.disconnect
    producer.disconnect
    duplex.disconnect

    # Shutdown the EM loop
    EM.add_timer(1) { EM.stop }
  end
end
