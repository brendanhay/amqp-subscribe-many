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
    # @param metadata [AMQP::Header] The message headers.
    # @param payload [String] The message payload.
    # @raise [NotImplementedError]
    # @api protected
    def on_message(metadata, payload)
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
        # An AMQP::Consumer is being explicitly provisioned versus relying on
        # the AMQP::Queue#subscription facilities for provisioning one, because
        # this one allows users of this library to register multiple
        # subscriptions thereon.
        c = AMQP::Consumer.new(channel, q)

        c.consume().on_delivery do |metadata, payload|
          log.debug("Receieved message on channel #{metadata.channel.id} from queue #{queue.inspect}")

          # If an exception is raised in on_message, we do not acknowledge the
          # message was actually processed.
          begin
            on_message(metadata, payload)
            metadata.ack
          rescue => e
            puts "Received exception #{e} for payload #{payload.inspect} " +
              "under #{metadata.headers.inspect} with backtrace "+
              "#{e.backtrace.join('\n')}; continuing..."
          end
        end
      end

      self
    end
  end

end
