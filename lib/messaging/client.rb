# This Source Code Form is subject to the terms of
# the Mozilla Public License, v. 2.0.
# A copy of the MPL can be found in the LICENSE file or
# you can obtain it at http://mozilla.org/MPL/2.0/.
#

require "amqp"

module Messaging

  # Default exchange type
  EXCHANGE_TYPE = "direct"

  # Provides methods and constants required to establish an AMQP
  # connection and channel with failure handling and recovery.
  module Client

    # Defaults for declared exchanges and queues
    OPTIONS = {
      :auto_delete => false,
      :durable     => true
    }

    # Declare an exchange on the specified channel.
    #
    # @param channel [AMQP::Channel]
    # @param name [String]
    # @param type [String]
    # @yieldparam exchange [AMQP::Exchange]
    # @return [AMQP::Exchange]
    # @api public
    def declare_exchange(channel, name, type)
      exchange =
        # Check if default options need to be supplied
        if default_exchange?(name)
          channel.default_exchange
        else
          channel.send(type, name, OPTIONS)
        end

      puts "Exchange #{exchange.name.inspect} declared"

      exchange
    end

    # Declare and bind a queue to the specified exchange via the
    # supplied routing key.
    #
    # @param channel [AMQP::Channel]
    # @param exchange [AMQP::Exchange]
    # @param name [String]
    # @param key [String]
    # @yieldparam queue [AMQP::Queue]
    # @return [AMQP::Queue]
    # @api public
    def declare_queue(channel, exchange, name, key)
      channel.queue(name, OPTIONS) do |queue|
        # Check if additional bindings are needed
        unless default_exchange?(exchange.name)
          queue.bind(exchange, OPTIONS.merge(:routing_key => key))
        end

        puts "Queue #{queue.name.inspect} bound to #{exchange.name.inspect}"
      end
    end

    protected

    # Open an AMQP::Channel with auto-recovery and error handling.
    #
    # @param connection [AMQP::Connection]
    # @param prefetch [Integer, nil]
    # @return [AMQP::Channel]
    # @api private
    def open_channel(connection, prefetch = nil)
      AMQP::Channel.new(connection) do |channel, open_ok|
        channel.auto_recovery = true
        channel.prefetch(prefetch) if prefetch

        channel.on_error do |ch, error|
          puts "Channel error: #{error.reply_text}, recovering"
        end

        puts "Channel #{channel.id} created"
      end
    end

    # Create an AMQP::Connection with auto-reconnect and error handling.
    #
    # @param uri [String] The AMQP URI to connect to.
    # @param delay [Integer] Time to delay between reconnection attempts.
    # @return [AMQP::Connection]
    # @api private
    def open_connection(uri, delay = 5)
      options = AMQP::Client.parse_connection_uri(uri)

      AMQP.start(options) do |connection, open_ok|
        connection.on_recovery do |conn, settings|
          puts "Connection to #{uri} recovered"
        end

        # Handle TCP connection errors
        connection.on_tcp_connection_loss do |conn, settings|
          puts "Connection to #{uri} lost, reconnecting"

          conn.periodically_reconnect(delay)
        end

        # Handle general errors
        connection.on_error do |conn, error|
          puts "Connection to #{uri} lost, reconnecting"

          conn.periodically_reconnect(delay)
        end

        puts "Connection to #{uri} started"
      end
    end

    private

    # @param name [String]
    # @return [Boolean]
    # @api private
    def default_exchange?(name)
      ["amq.direct",
       "amq.fanout",
       "amq.topic",
       "amqp.headers",
       "amqp.match"].include?(name)
    end
  end

end
