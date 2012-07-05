module Messaging

  #
  # Used as a base class for creating a processor which can have many
  # subscriptions and a single message handler.
  #
  # It wraps the instantiation of both a producer and a consumer.
  #
  class Base

    # Subscribe to a queue which will invoke {#on_message}
    #
    # @param exchange [String]
    # @param type [String]
    # @param queue [String]
    # @param key [String]
    # @return [Array<Array(String, String, String, String)>]
    # @api public
    def self.subscribe(exchange, type, queue, key)
      subscriptions << [exchange, type, queue, key]
    end

    # A list of subscriptions created by {.subscribe}
    # Intended for internal use.
    #
    # @return [Array<Array(String, String, String, String)>]
    # @api private
    def self.subscriptions
      @subscriptions ||= []
    end

    # @return [Messaging::Producer]
    # @api private
    attr_reader :producer

    # @return [Messaging::Consumer]
    # @api private
    attr_reader :consumer

    # @param options [Hash]
    # @option options [String] :publish_to
    # @option options [Array<String>] :consume_from
    # @option options [Integer] :prefetch
    # @return [Messaging::Base]
    # @api public
    def initialize(options = {})
      if publish_to = options[:publish_to]
        @producer = Messaging::Producer.new(publish_to)
      end

      if consume_from = options[:consume_from]
        @consumer = Messaging::Consumer.new(consume_from, options[:prefetch] || 1)

        setup_subscriptions
      elsif subscriptions.length > 0
        raise(ArgumentError, "Subscriptions present but no consume_from uris specified")
      end
    end

    # Overriden in the child class hierarchy to handle message delivery.
    #
    # @param meta [AMQP::Header]
    # @param payload [Object]
    # @raise [NotImplementedError]
    # @api public
    def on_message(meta, payload)
      throw NotImplementedError
    end

    # Publish a payload to the specified exchange/key pair.
    #
    # @param exchange [String]
    # @param type [String]
    # @param key [String]
    # @param payload [Object]
    # @param options [Hash]
    # @return [Messaging::Producer]
    # @api public
    def publish(exchange, type, key, payload, options = {})
      if producer
        producer.publish(exchange, type, key, payload, options)
      else
        raise(RuntimeError, "Producer connection uri not specified")
      end
    end

    # Disconnect/close both the producer and consumer connections and channels.
    #
    # @return []
    # @api public
    def disconnect
      producer.disconnect if producer
      consumer.disconnect if consumer
    end

    private

    # A list of subscriptions created by {.subscribe}
    #
    # @return [Array<Array(String, String, String, String)>]
    # @api private
    def subscriptions
      self.class.subscriptions
    end

    # @api private
    def setup_subscriptions
      if subscriptions.length == 0
        raise(ArgumentError, "No subscriptions specified")
      end

      subscriptions.each do |args|
        consumer.subscribe(*args) do |meta, payload|
          # If this throws an exception, the connection
          # will be closed, and the message requeued by the broker.
          on_message(meta, payload)

          meta.ack
        end
      end
    end
  end

end
