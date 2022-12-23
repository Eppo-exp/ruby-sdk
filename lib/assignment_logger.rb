# frozen_string_literal: true

require 'custom_errors'
module EppoClient
  # The base assignment logger class to override
  class AssignmentLogger
    def log_assignment(_assignment)
      raise(EppoClient::AssignmentLoggerError, 'log_assignment has not been set up')
    end
  end
end
