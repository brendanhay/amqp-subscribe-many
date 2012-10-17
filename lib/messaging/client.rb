require "amqp"

module Messaging

  #
  # Raised when unrecoverable connection and channel errors are encountered.
  #
  class MessagingError < StandardError; end

  #
  # Provides methods and constants required to establish an AMQP
  # connection and channel with failure handling and recovery.
  # @see http://www.rabbitmq.com/amqp-0-9-1-reference.html#constants
  #   For a list of error codes that will cause an exception to be raised
  #   rather than invoking automatic recovery.
  #
  module Client

    # Create an AMQP::Connection with auto-reconnect and error handling.
    #
    # @param uri [String] The AMQP URI to connect to.
    # @param delay [Integer, nil] Time to delay between reconnection attempts.
    # @return [AMQP::Connection]
    # @api public
    def open_connection(uri, delay = nil)
      delay ||= config.reconnect_delay
      options = AMQP::Client.parse_connection_uri(uri)

      res = AMQP.connect(options) do |connection, open_ok|
        # Handle TCP connection errors
        connection.on_tcp_connection_loss do |conn, settings|
          log.error("Connection to #{uri.inspect} lost, reconnecting")

          conn.periodically_reconnect(delay)
        end

        # Handle general errors
        connection.on_error do |conn, error|
          log.error("Connection to #{uri.inspect} lost, reconnecting")

          if (402..540).include?(error.reply_code)
            raise(MessagingError, "Connection exception: #{error.reply_text.inspect}")
          end

          conn.periodically_reconnect(delay)
        end

        log.debug("Connection to #{uri.inspect} started")
      end

      register_connection(res)
    end

    # Open an AMQP::Channel with auto-recovery and error handling.
    #
    # @param connection [AMQP::Connection]
    # @param prefetch [Integer, nil]
    # @return [AMQP::Channel]
    # @api public
    def open_channel(connection, prefetch = nil)
      res = AMQP::Channel.new(connection) do |channel, open_ok|
        channel.auto_recovery = true
        channel.prefetch(prefetch) if prefetch

        channel.on_error do |ch, error|
          log.error("Channel error #{error.reply_text.inspect}, recovering")

          # Raise erroneous channel calls/conditions
          # rather than endlessly retrying
          if (403..406).include?(error.reply_code)
            raise(MessagingError, "Channel exception: #{error.reply_text.inspect}")
          end
        end

        log.debug("Channel #{channel.id} created")
      end

      register_channel(res)
    end

    # Declare an exchange on the specified channel.
    #
    # @param channel [AMQP::Channel]
    # @param name [String]
    # @param type [String]
    # @param options [Hash]
    # @return [AMQP::Exchange]
    # @api public
    def declare_exchange(channel, name, type, options = {})
      exchange =
        # Check if default options need to be supplied to a non-default delcaration
        if default_exchange?(name)
          channel.default_exchange
        else
          channel.send(type, name, options)
        end

      log.debug("Exchange #{exchange.name.inspect} declared")

      exchange
    end

    # Declare and bind a queue to the specified exchange via the
    # supplied routing key.
    #
    # @param channel [AMQP::Channel]
    # @param exchange [AMQP::Exchange]
    # @param name [String]
    # @param key [String]
    # @param options [Hash]
    # @return [AMQP::Queue]
    # @api public
    def declare_queue(channel, exchange, name, key, options = {})
      channel.queue(name, options) do |queue|
        # Check if additional bindings are needed
        unless default_exchange?(exchange.name)
          queue.bind(exchange, { :routing_key => key })
        end

        log.debug("Queue #{queue.name.inspect} bound to #{exchange.name.inspect}")
      end
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

    protected

    # @return [#info, #debug, #error]
    # @api protected
    def log
      config.logger
    end

    # @return [Messaging::Configuration]
    # @api protected
    def config
      Configuration.instance
    end

    private

    # @return [Array<AMQP::Channels>]
    # @api private
    def channels
      @channels ||= []
    end

    # @param channel [AMQP::Channel]
    # @return [AMQP::Channel]
    # @api private
    def register_channel(channel)
      channels << channel
      channel
    end

    # @return [Array<AMQP::Connection>]
    # @api private
    def connections
      @connections ||= []
    end

    # @param connection [AMQP::Connection]
    # @return [AMQP::Connection]
    # @api private
    def register_connection(connection)
      connections << connection
      connection
    end

    # @param name [String]
    # @return [Boolean]
    # @api private
    def default_exchange?(name)
      ["",
       "amq.default",
       "amq.direct",
       "amq.fanout",
       "amq.topic",
       "amq.headers",
       "amq.match"].include?(name)
    end
  end

end
