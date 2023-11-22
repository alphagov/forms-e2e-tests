require "forwardable"
require "logger"

module Logging
  def logger
    Logging.logger
  end

  def self.logger
    @formatter ||= proc do |severity, _time, _progname, msg|
      severity = severity == "DEBUG" ? "#{severity}: " : nil
      "#{severity}#{msg}\n"
    end
    @logger ||= Logger.new($stdout)
      .tap { |logger| logger.level = ENV.fetch("LOG_LEVEL", Logger::WARN) }
      .tap { |logger| logger.formatter = @formatter }
  end
end

RSpec.configure do |config|
  config.include Logging
end

