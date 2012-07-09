require_relative "test_helper"

class DummyClient
  include Messaging::Client
end

class ClientTest < MiniTest::Unit::TestCase
  def setup
    @client = DummyClient.new
    @uri = "amqp://guest:guest@localhost:5672"
  end

  def test_open_connection_adds_retry_handlers
    delay = 3

    # Connection yield param
    conn = mock()

    # on_tcp_connection_loss handler sets periodically reconnect
    on_tcp_loss = mock()
    on_tcp_loss.expects(:periodically_reconnect).with(delay)
    on_tcp_loss.expects(:to_ary)

    # A retryable/recoverable error code
    error = mock()
    error.expects(:reply_code).returns(1)

    # on_error handler sets periodically reconnect
    on_error = mock()
    on_error.expects(:periodically_reconnect).with(delay)

    conn.expects(:on_tcp_connection_loss).yields(on_tcp_loss)
    conn.expects(:on_error).yields(on_error, error)
    conn.expects(:to_ary)

    AMQP.stubs(:connect).yields(conn)

    @client.open_connection(@uri, delay)
  end

  def test_open_channel_adds_recovery_handlers
    prefetch = 16

    # Channel yield param
    chan = mock()
    chan.expects(:on_error)
    chan.expects(:auto_recovery=).with(true)
    chan.expects(:prefetch).with(prefetch)
    chan.expects(:id)

    AMQP::Channel.stubs(:new).yields(chan, {})

    @client.open_channel(mock(), prefetch)
  end
end


