# frozen_string_literal: true

require 'constants'

require 'logger'

# The helper module for logging
module EppoClient
  @stdout_logger = Logger.new($stdout)
  @stdout_logger.level = DEFAULT_LOGGER_LEVEL

  def self.logger
    @stdout_logger
  end
end
