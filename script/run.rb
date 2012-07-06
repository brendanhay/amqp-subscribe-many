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

class ConsumerProcessor
  include Messaging::Consumer

  subscribe(EXCHANGE, TYPE, QUEUE, KEY)

  def initialize(options)
    @consume_from = options[:consume_from]
  end

  def on_message(meta, payload)
    puts "ConsumeProcessor: Channel #{meta.channel.id} received payload #{payload.inspect}"
  end
end

class ProducerProcessor
  include Messaging::Producer

  def initialize(options)
    @publish_to = options[:publish_to]
  end
end

class DuplexProcessor
  include Messaging::Producer
  include Messaging::Consumer

  subscribe(EXCHANGE, TYPE, QUEUE, KEY)

  def initialize(options)
    @publish_to = options[:publish_to]
    @consume_from = options[:consume_from]
  end

  def on_message(meta, payload)
    puts "DuplexProcessor: Channel #{meta.channel.id} received payload #{payload.inspect}"
  end
end

EM.run do
  # Load the config
  config = YAML::load_file(File.dirname(__FILE__) + "/config.yml")

  # Instantiate the processors
  consumer = ConsumerProcessor.new(config)
  producer = ProducerProcessor.new(config)
  duplex   = DuplexProcessor.new(config)

  # Start the consumers
  consumer.consume
  duplex.consume

  # Create a handle to the publish timer, to cancel later
  timer = EM.add_periodic_timer(1) do
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
