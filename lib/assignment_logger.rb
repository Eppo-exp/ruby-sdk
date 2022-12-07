# frozen_string_literal: true

module EppoClient
  # The base logger class to override
  class AssignmentLogger
    def log_assignment(_assignment)
      raise(StandardError, 'log_assignment must be overriden in order to use AssignmentLogger!')
    end
  end
end
