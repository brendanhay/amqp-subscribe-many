# This Source Code Form is subject to the terms of
# the Mozilla Public License, v. 2.0.
# A copy of the MPL can be found in the LICENSE file or
# you can obtain it at http://mozilla.org/MPL/2.0/.
#
# Brendan Hay
# Copyright (c) 2012 Brendan Hay <brendan@soundcloud.com>
#

require "amqp"

module Messaging

  # Provides a publish mechanism for a single AMQP broker
  class Producer
    include Client

    # @return [String]
    # @api public
    attr_reader :uri

    # @param uri [String]
    # @return [Messaging::Producer]
    # @api public
    def initialize(uri = "amqp://guest:guest@localhost:5672")
      @uri = uri
      @exchanges = {}
    end

    # Publish a payload to the specified exchange/key pair.
    #
    # @param exchange [String]
    # @param key [String]
    # @param payload [Object]
    # @return [Messaging::Producer]
    # @api public
    def publish(exchange, key, payload)
      ex = @exchanges[exchange] ||=
        declare_exchange(channel, exchange, EXCHANGE_TYPE)

      ex.publish(payload, {
        :exchange    => exchange,
        :routing_key => key
      })

      self
    end

    private

    # @return [AMQP::Channel]
    # @api private
    def channel
      @channel ||= open_channel(connection)
    end

    # @return [AMQP::Connection]
    # @api private
    def connection
      @connection ||= open_connection(uri)
    end
  end

end
