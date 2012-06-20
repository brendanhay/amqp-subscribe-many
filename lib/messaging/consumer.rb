require "amqp"

module Messaging

  # Provides a mechanism to subscribe to identical queues on
  # multiple seperate AMQP brokers
  class Consumer
    include Client

    # @return [Array<String>]
    # @api public
    attr_reader :uris

    # @return [Integer, nil]
    # @api public
    attr_reader :prefetch

    # @param uris [Array<String>]
    # @param prefetch [Integer, nil]
    # @return [Messaging::Consumer]
    # @api public
    def initialize(uris = ["amqp://guest:guest@localhost:5672"], prefetch = 1)
      @uris, @prefetch = uris, prefetch
    end

    # Subscribe to a queue which will invoke the supplied block when
    # a message is received.
    # Additionally declaring a binding to the specified exchange/key pair.
    #
    # @param exchange [String]
    # @param queue [String]
    # @param key [String]
    # @yieldparam meta [AMQP::Header]
    # @yieldparam payload [Object]
    # @return [Messaging::Consumer]
    # @api public
    def subscribe(exchange, queue, key, &block)
      channels.each do |channel|
        ex = declare_exchange(channel, exchange, EXCHANGE_TYPE)
        q  = declare_queue(channel, ex, queue, key)

        q.subscribe(:ack => true) do |meta, payload|
          puts "Channel #{channel.id} received payload #{payload}"

          block.call(meta, payload)
        end
      end

      self
    end

    private

    # @return [Array<AMQP::Channel>]
    # @api private
    def channels
      @channels ||= connections.map do |connection|
        open_channel(connection, prefetch)
      end
    end

    # @return [Array<AMQP::Connection>]
    # @api private
    def connections
      @connections ||= uris.map { |uri| open_connection(uri) }
    end
  end

end
