require "simplecov"

SimpleCov.start

require "minitest/autorun"
require "mocha"
require "messaging"
require "logger"

class MiniTestSetup < MiniTest::Unit
  def _run_suites(suites, type)
    Messaging::Configuration.setup do |config|
      config.logger.level = Logger::Severity::UNKNOWN
    end

    super
  end
end

MiniTest::Unit.runner = MiniTestSetup.new


