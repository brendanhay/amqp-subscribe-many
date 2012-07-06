module Messaging

  module ConsumerExtensions

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

  module Consumer
    def self.included(base)
      base.extend(ConsumerExtensions)
    end

    # @return [Array<String>]
    # @api protected
    attr_reader :consume_from

    # @return [Integer, nil]
    # @api protected
    attr_reader :consume_prefetch

    # @return [Messaging::Consumer]
    # @api public
    def consume
      unless consumer_channels
        @consumer_channels ||= consumer_connections.map do |conn|
          Client.open_channel(conn, consume_prefetch || 1)
        end

        subscriptions.each { |args| subscribe(*args) }
      end

      self
    end

    # Subscribe to a queue which will invoke the supplied block when
    # a message is received.
    # Additionally declaring a binding to the specified exchange/key pair.
    #
    # @param exchange [String]
    # @param type [String]
    # @param queue [String]
    # @param key [String]
    # @return [Messaging::Consumer]
    # @api public
    def subscribe(exchange, type, queue, key)
      consumer_channels.each do |channel|
        ex = Client.declare_exchange(channel, exchange, type)
        q = Client.declare_queue(channel, ex, queue, key)

        q.subscribe(:ack => true) do |meta, payload|
          # If this raises an exception, the connection
          # will be closed, and the message requeued by the broker.
          on_message(meta, payload)

          meta.ack
        end
      end

      self
    end

    # @throws [NotImplementedError]
    # @api protected
    def on_message(meta, payload)
      raise NotImplementedError
    end

    # Close all consumer_channels and then disconnect all the consumer_connections.
    #
    # @return []
    # @api public
    def disconnect
      consumer_channels.each do |chan|
        chan.close
      end

      consumer_connections.each do |conn|
        conn.disconnect && True
      end
    end

    private

    # @return [Array<AMQP::Connection>]
    # @api private
    def consumer_connections
      unless consume_from
        raise(RuntimeError, "attr_reader 'consume_from' not set for mixin Messaging::Consumer")
      end

      @consumer_connections ||= consume_from.map do |uri|
        Client.open_connection(uri)
      end
    end

    # @return [Array<AMQP::Channel>]
    # @api private
    def consumer_channels
      @consumer_channels
    end

    # @return [Array<Array(String, String, String, String)>]
    # @api private
    def subscriptions
      self.class.subscriptions
    end
  end

end
