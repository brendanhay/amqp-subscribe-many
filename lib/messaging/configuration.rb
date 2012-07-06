require "singleton"

module Messaging

  # Global configuration for producer and consumer mixins.
  class Configuration
    include Singleton

    # @yieldparam [Messaging::Configuration] config
    # @api public
    def self.setup(&block)
      yield(Configuration.instance)
    end

    # @!attribute [r] publish_to
    #   @return [String]
    attr_accessor :publish_to

    # @!attribute [r] consume_from
    #   @return [Array<String>]
    attr_accessor :consume_from

    # @!attribute [r] prefetch
    #   @return [Integer]
    attr_accessor :prefetch

    # @!attribute [r] exchange_options
    #   @return [Hash]
    attr_accessor :exchange_options

    # @!attribute [r] queue_options
    #   @return [Hash]
    attr_accessor :queue_options

    # @!attribute [r] reconnect_delay
    #   @return [Integer]
    attr_accessor :reconnect_delay

    # @!attribute [r] logger
    #   @return [#info, #debug, #error]
    attr_accessor :logger

    # @api private
    def initialize
      @publish_to       = "amqp://guest:guest@localhost:5672"
      @consume_from     = [publish_to]
      @prefetch         = 1
      @exchange_options = { :auto_delete => false, :durable => true }
      @queue_options    = exchange_options
      @reconnect_delay  = 5
      @logger           = nil
    end
  end

end
