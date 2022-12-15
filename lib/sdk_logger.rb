# frozen_string_literal: true

require 'logger'

# The helper module for logging
module EppoClient
  @stdout_logger = Logger.new($stdout)
  @stderr_logger = Logger.new($stderr)

  def self.logger(type)
    case type
    when 'out'
      @stdout_logger
    when 'err'
      @stderr_logger
    else
      @stderr_logger.error("[Eppo SDK] Invalid logger type: #{type}")
    end
  end
end
