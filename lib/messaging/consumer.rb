require "amqp"

module Messaging

  #
  # Provides a mechanism to subscribe to identical queues on
  # multiple seperate AMQP brokers
  #
  class Consumer
    include Client

    # @return [Array<AMQP::Connection>]
    # @api private
    attr_reader :connections

    # @return [Array<AMQP::Channel>]
    # @api private
    attr_reader :channels

    # @param uris [Array<String>]
    # @param prefetch [Integer, nil]
    # @return [Messaging::Consumer]
    # @api public
    def initialize(uris, prefetch = 1)
      @connections = uris.map { |uri| open_connection(uri) }
      @channels = @connections.map { |conn| open_channel(conn, prefetch) }
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
      channels.each do |channel|
        ex = declare_exchange(channel, exchange, type)
        declare_queue(channel, ex, queue, key).subscribe(:ack => true, &block)
      end

      self
    end

    # Close all channels and then disconnect all the connections.
    #
    # @return []
    # @api public
    def disconnect
      channels.each do |chan|
        chan.close
      end

      connections.each do |conn|
        conn.disconnect
      end
    end
  end

end
