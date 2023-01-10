# frozen_string_literal: true

module EppoClient
  # A custom error class for AssignmentLogger
  class AssignmentLoggerError < StandardError
    def initialize(message)
      super("AssignmentLoggerError: #{message}")
    end
  end

  # A custom error class for unauthorized requests
  class UnauthorizedError < StandardError
    def initialize(message)
      super("Unauthorized: #{message}")
    end
  end

  # A custom error class for HTTP requests
  class HttpRequestError < StandardError
    attr_reader :status_code

    def initialize(message, status_code)
      @status_code = status_code
      super("HttpRequestError: #{message}")
    end
  end

  # A custom error class for invalid values
  class InvalidValueError < StandardError
    def initialize(message)
      super("InvalidValueError: #{message}")
    end
  end
end
