module Messaging

  class Base

    def self.subscriptions
      @subscriptions ||= []
    end

    def self.subscribe(*args)
      @subscriptions ||= []
      @subscriptions << args
    end

    URI = "amqp://guest:guest@localhost:5672"

    def initialize(publish_to = URI, consume_from = [URI])
      @producer = Messaging::Producer.new(publish_to)
      @consumer = Messaging::Consumer.new(consume_from)

      setup_subscriptions
    end

    def on_message(meta, payload)
      raise NotImplementedError
    end

    def publish(*args)
      @producer.send(:publish, *args)
    end

    def disconnect(&block)
      @producer.disconnect
      @consumer.disconnect

      EM.next_tick do
        block.call
      end
    end

    private

    def setup_subscriptions
      self.class.subscriptions.each do |args|
        @consumer.send(:subscribe, *args) do |meta, payload|
          on_message(meta, payload)

          meta.ack
        end
      end
    end
  end

end
