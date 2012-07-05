module Messaging

  #
  # Used as a base class for creating a processor which can have many
  # subscriptions and a single message handler.
  #
  # It essentially wraps the instantiation of both a producer and a consumer.
  #
  class Base
    class << self


      def subscribe(*args)
        @subscriptions ||= []
        @subscriptions << args
      end

      def subscriptions
        @subscriptions ||= []
      end

      def on_message(&block)
        @on_message = block
      end

      def on_message_block
        @on_message
      end
    end

    URI = "amqp://guest:guest@localhost:5672"

    def initialize(publish_to = URI, consume_from = [URI])
      @producer = Messaging::Producer.new(publish_to)
      @consumer = Messaging::Consumer.new(consume_from)

      self.class.subscriptions.each do |args|
        @consumer.send(:subscribe, *args) do |meta, payload|
          # If this block.call throws an exception, the connection
          # will be closed, and the message requeued.
          self.class.on_message_block.call(meta, payload)

          meta.ack
        end
      end
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
