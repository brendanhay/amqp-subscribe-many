if defined?(ActiveSupport::Deprecation)
  deprecation_message = "amqp-subscribe-many: require 'messaging' is deprecated. Please use require 'amqp_subscribe_many'"
  ActiveSupport::Deprecation.warn(deprecation_message)
end
require_relative 'amqp_subscribe_many'
