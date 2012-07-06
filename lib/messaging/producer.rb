module Messaging

  module Producer

    # @return [Array<String>]
    # @api protected
    attr_reader :publish_to

    # @return [Hash(String, AMQP::Exchange)]
    # @api private
    def producer_exchanges
      @producer_exchanges ||= {}
    end

    # @return [AMQP::Connection]
    # @api private
    def producer_connection
      unless publish_to
        raise(RuntimeError, "attr_reader 'publish_to' not set for mixin Messaging::Producer")
      end

      @producer_connection ||= Client.open_connection(publish_to)
    end

    # @return [AMQP::Channel]
    # @api private
    def producer_channel
      @producer_channel ||= Client.open_channel(producer_connection)
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
      ex = producer_exchanges[exchange] ||=
        Client.declare_exchange(producer_channel, exchange, type, options)

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
      producer_channel.close do |close_ok|
        producer_connection.disconnect
      end
    end
  end

end
