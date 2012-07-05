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

  module ConsumerM
    include Client

    def self.included(base)
      base.extend(ConsumerExtensions)
    end

    # @return [Array<AMQP::Connection>]
    # @api private
    attr_reader :consumer_connections

    # @return [Array<AMQP::Channel>]
    # @api private
    attr_reader :consumer_channels

    def initialize(*args, &block)
      super

      @consumer_connections = @consume_from.map { |uri| open_connection(uri) }
      @consumer_channels = @consumer_connections.map do |conn|
        open_channel(conn, @prefetch)
      end

      self.class.subscriptions.each do |args|
        subscribe(*args) do |meta, payload|
          # If this throws an exception, the connection
          # will be closed, and the message requeued by the broker.
          on_message(meta, payload)

          meta.ack
        end
      end
    end

    # Subscribe to a queue which will invoke the supplied block when
    # a message is received.
    # Additionally declaring a binding to the specified exchange/key pair.
    #
    # @param exchange [String]
    # @param type [String]
    # @param queue [String]
    # @param key [String]
    # @yieldparam meta [AMQP::Header]
    # @yieldparam payload [Object]
    # @return [Messaging::Consumer]
    # @api public
    def subscribe(exchange, type, queue, key, &block)
      consumer_channels.each do |channel|
        ex = declare_exchange(channel, exchange, type)
        declare_queue(channel, ex, queue, key).subscribe(:ack => true, &block)
      end

      self
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
        conn.disconnect
      end
    end
  end

end
