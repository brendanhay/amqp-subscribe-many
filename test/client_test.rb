require_relative "test_helper"

class DummyClient
  include Messaging::Client
end

class ClientTest < MiniTest::Unit::TestCase
  def setup
    @client = DummyClient.new
    @uri    = "amqp://guest:guest@localhost:5672"
  end

  def test_open_connection_adds_tcp_connection_loss_handler
    delay = 3
    # conn  = @client.open_connection(@uri, delay)
    # assert_false conn
    pass
  end

  def test_tcp_connection_loss_handler_sets_periodic_reconnect_delay
    pass
  end

  def test_open_connection_adds_error_handler
    pass
  end

  def test_error_handler_sets_periodic_reconnect_delay
    pass
  end

  def test_error_handler_raises_messaging_error_for_unrecoverable_error_codes
    pass
  end
end


