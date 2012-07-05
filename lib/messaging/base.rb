module Messaging

  #
  # Used as a base class for creating a processor which can have many
  # subscriptions and a single message handler.
  #
  # It wraps the instantiation of both a producer and a consumer.
  #
  class Base
    class << self

      # Subscribe to a queue which will invoke {#on_message}
      #
      # @param exchange [String]
      # @param type [String]
      # @param queue [String]
      # @param key [String]
      # @return [Array<Array(String, String, String, String)>]
      # @api public
      def subscribe(exchange, type, queue, key)
        subscriptions << [exchange, type, queue, key]
      end

      # A list of subscriptions created by {.subscribe}
      # Intended for internal use.
      #
      # @return [Array<Array(String, String, String, String)>]
      # @api private
      def subscriptions
        @subscriptions ||= []
      end
    end

    URI = "amqp://guest:guest@localhost:5672"

    def initialize(publish_to = URI, consume_from = [URI])
      @producer = Messaging::Producer.new(publish_to)
      @consumer = Messaging::Consumer.new(consume_from)

      self.class.subscriptions.each do |args|
        @consumer.subscribe(*args) do |meta, payload|
          # If this throws an exception, the connection
          # will be closed, and the message requeued by the broker.
          on_message(meta, payload)

          meta.ack
        end
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
      @producer.publish(exchange, type, key, payload, options)
    end

    # Disconnect/close both the producer and consumer connections and channels.
    #
    # @return []
    # @api public
    def disconnect
      @producer.disconnect
      @consumer.disconnect
    end
  end

end
