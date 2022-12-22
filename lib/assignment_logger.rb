# frozen_string_literal: true

require 'custom_errors'
module EppoClient
  # The base assignment logger class to override
  class AssignmentLogger
    def log_assignment(_assignment)
      raise(EppoClient::AssignmentLoggerError, 'Cannot use log_assignment unless it is overridden in AssignmentLogger!')
    end
  end
end
