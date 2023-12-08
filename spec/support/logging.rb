require "forwardable"
require "logger"

SPEC_DIR = "#{File.dirname(__dir__)}#{File::SEPARATOR}"

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

  def start_tracing
    return unless ENV.fetch("TRACE", false)

    set_trace_func proc { |event, file, line, id, binding, classname|
      if trace_event?(event, file, line)
        printf(
          "TRACE: %30s: %s\n",
          "#{file.delete_prefix(SPEC_DIR)}:#{line}",
          source(file, line),
        )
      end
    }

    at_exit { stop_tracing }
  end

  def stop_tracing
    set_trace_func(nil)
  end

private

  def trace_event?(event, file, line)
    event == "line" \
      && file.start_with?(SPEC_DIR) \
      && file != __FILE__ \
      && !source(file, line).start_with?("logger")
  end

  def source(file, line)
    @@source_locations ||= Hash.new do |hash, key|
      File.readlines(key).map { _1.strip }
    end


    @@source_locations[file][line - 1]
  end
end

RSpec.configure do |config|
  config.include Logging
end

