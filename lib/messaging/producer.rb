require "amqp"

module Messaging

  #
  # Provides a publish mechanism for a single AMQP broker
  #
  class Producer
    include Client

    # @return [AMQP::Connection]
    # @api private
    attr_reader :connection

    # @return [AMQP::Channel]
    # @api private
    attr_reader :channel

    # @param uri [String]
    # @return [Messaging::Producer]
    # @api public
    def initialize(uri)
      @exchanges  = {}
      @connection = open_connection(uri)
      @channel    = open_channel(@connection)
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
      ex = @exchanges[exchange] ||=
        declare_exchange(channel, exchange, type, options)

      ex.publish(payload, {
        :exchange    => exchange,
        :routing_key => key
      })

      self
    end

    # Close the channel and then disconnect the connection.
    #
    # @return []
    # @api public
    def disconnect
      channel.close do |close_ok|
        connection.disconnect
      end
    end
  end

end
