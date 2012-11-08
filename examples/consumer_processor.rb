require "amqp_subscribe_many"

# A consume only example
class ConsumerProcessor
  include Messaging::Consumer

  subscribe("exchange", "direct", "queue", "key")

  def on_message(meta, payload)
    log.info("ConsumeProcessor channel #{meta.channel.id} received payload #{payload.inspect}")
  end
end
