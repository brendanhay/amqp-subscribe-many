module Messaging

  module Consumer
    include Client

    # DSL methods which are used to extend the target when
    # {Messaging::Consumer} is included into a class.
    module Extensions

      # Subscribe to a queue which will invoke {Messaging::Consumer#on_message}
      # upon receiving a message.
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

      # A list of subscriptions intended for internal use.
      #
      # @return [Array<Array(String, String, String, String)>]
      # @api private
      def subscriptions
        @subscriptions ||= []
      end

    end

    # Extends the class into which the Consumer mixin is included with
    # a {Messaging::Consumer.subscribe} method for declaratively
    # specifying Consumer subscriptions.
    #
    # @api public
    def self.included(base)
      base.send(:extend, Extensions)
    end

    # Opens connections, channels, and sets up and specified subscriptions
    # invoking {Messaging::Consumer#on_message} when a payload is received.
    #
    # @return [Messaging::Consumer]
    # @api public
    def consume
      unless consumer_channels
        @consumer_channels ||= consumer_connections.map do |conn|
          open_channel(conn, config.prefetch)
        end

        subscriptions.each { |args| subscribe(*args) }
      end

      self
    end

    # Invoked when a message is received from any of the subscriptions.
    #
    # @param meta [AMQP::Header] A wrapper around the AMQP headers and other metadata
    # @param payload [String] The message payload
    # @raise [NotImplementedError]
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
        conn.disconnect
      end
    end

    private

    # @return [Array<AMQP::Connection>]
    # @api private
    def consumer_connections
      @consumer_connections ||= config.consume_from.map do |uri|
        open_connection(uri)
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

    # Subscribe to a queue which will invoke the supplied block when
    # a message is received.
    # Additionally declaring a binding to the specified exchange/key pair.
    #
    # @param exchange [String]
    # @param type [String]
    # @param queue [String]
    # @param key [String]
    # @return [Messaging::Consumer]
    # @api private
    def subscribe(exchange, type, queue, key)
      consumer_channels.each do |channel|
        ex = declare_exchange(channel, exchange, type, config.exchange_options)
        q  = declare_queue(channel, ex, queue, key, config.queue_options)

        # Expliclity create an AMQP::Consumer rather than using
        # AMQP::Queue.subscription, which is a global singleton
        AMQP::Consumer.new(channel, q).consume.on_delivery do |meta, payload|
          log.debug("Receieved message on channel #{meta.channel.id} from queue #{queue.inspect}")

          # If an exception is raised in on_message, the message will not be
          # acknowledged and the exception will be logged and re-raised
          begin
            on_message(meta, payload)

            meta.ack
          rescue => ex
            log.error("Exception: #{ex}, " \
              "Payload: #{payload.inspect}, " \
              "Headers: #{meta.headers.inspect}\n" \
              "Backtrace:\n#{ex.backtrace.join('\n')}")

            # Re-raise the exception
            raise ex
          end
        end
      end

      self
    end
  end

end
