# frozen_string_literal: true

module EppoClient
  # The base logger class to override
  class AssignmentLogger
    def log_assignment(_assignment)
      raise(StandardError, 'Cannot use log_assignment unless it is overridden in AssignmentLogger!')
    end
  end
end
