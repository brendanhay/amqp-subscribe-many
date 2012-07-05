module Messaging

  module ProducerM
    include Client

    # @return [Hash(String, AMQP::Exchange)]
    # @api private
    attr_reader :producer_exchanges

    # @return [AMQP::Connection]
    # @api private
    attr_reader :producer_connection

    # @return [AMQP::Channel]
    # @api private
    attr_reader :producer_channel

    def initialize(*args, &block)
      super

      @producer_exchanges = {}
      @producer_connection = open_connection(@publish_to)
      @producer_channel = open_channel(@producer_connection)
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
        declare_exchange(producer_channel, exchange, type, options)

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
