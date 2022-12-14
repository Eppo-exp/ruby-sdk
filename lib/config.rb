# frozen_string_literal: true

module EppoClient
  # Class for configuring the Eppo client singleton
  class Config
    attr_reader :api_key, :assignment_logger, :base_url

    def initialize(api_key, assignment_logger: AssignmentLogger.new, base_url: 'https://eppo.cloud/api')
      @api_key = api_key
      @assignment_logger = assignment_logger
      @base_url = base_url
    end

    def validate
      EppoClient.validate_not_blank('api_key', @api_key)
    end

    # Hide instance variables from logs
    def inspect
      "#<EppoClient::Config:#{object_id}>"
    end
  end
end

require 'validation'
require 'assignment_logger'
