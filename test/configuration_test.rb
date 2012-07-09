require_relative "test_helper"

class ConfigurationTest < MiniTest::Unit::TestCase
  def setup
    Messaging::Configuration.instance_variable_set(
      "@__instance__",
      Messaging::Configuration.send(:new)
    )

    @config = Messaging::Configuration
  end

  def test_publish_to
    assert(@config.instance.publish_to)

    expected = "ballsacks"
    @config.setup { |c| c.publish_to = expected }

    assert_equal(expected, @config.instance.publish_to)
  end

  def test_consume_from
    assert(@config.instance.consume_from.length > 0)

    expected = "nutsacks"
    @config.setup { |c| c.consume_from = expected }

    assert_equal(expected, @config.instance.consume_from)
  end

  def test_prefetch
    assert(@config.instance.prefetch > 0)

    expected = 7
    @config.setup { |c| c.prefetch = expected }

    assert_equal(expected, @config.instance.prefetch)
  end

  def test_exchange_options
    assert(@config.instance.exchange_options)

    expected = { :nonsense => true }
    @config.setup { |c| c.exchange_options = expected }

    assert_equal(expected, @config.instance.exchange_options)
  end

  def test_queue_options
    assert(@config.instance.queue_options)

    expected = { :high_five => "ok!" }
    @config.setup { |c| c.queue_options = expected }

    assert_equal(expected, @config.instance.queue_options)
  end

  def test_reconnect_delay
    assert(@config.instance.reconnect_delay > 0)

    expected = 12
    @config.setup { |c| c.reconnect_delay = expected }

    assert_equal(expected, @config.instance.reconnect_delay)
  end

  def test_logger
    assert(@config.instance.logger)

    expected = "ballsacks"
    @config.setup { |c| c.logger = expected }

    assert_equal(expected, @config.instance.logger)
  end
end
