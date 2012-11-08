require "amqp_subscribe_many"

# A publish only example
class ProducerProcessor
  include Messaging::Producer
end
