require "amqp_subscribe_many"

# A consume and publish example
class DuplexProcessor
  include Messaging::Producer
  include Messaging::Consumer

  subscribe("exchange", "direct", "queue", "key")

  def on_message(meta, payload)
    log.info("DuplexProcessor channel #{meta.channel.id} received payload #{payload.inspect}")
  end
end
