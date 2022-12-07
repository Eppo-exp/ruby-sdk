# frozen_string_literal: true

require 'singleton'
require 'concurrent/atomic/read_write_lock'

# This module scopes all the client SDK's classes and functions
module EppoClient
  @sdk_version = '1.1.1'
  @client = nil

  module_function

  def init(config)
    config.validate
    sdk_params = EppoClient::SdkParams.new(
      config.api_key, 'ruby', @sdk_version
    )
    http_client = EppoClient::HttpClient.new(config.base_url, sdk_params.formatted)
    puts http_client.get('randomized_assignment/v2/config')
    lock = Concurrent::ReadWriteLock.new
    lock.with_write_lock {
      !@client.nil? && @client.shutdown
      @client = EppoClient::Client.new
      @client.config_requestor = config_requestor
      @client.assignment_logger = assignment_logger
    }
    @client
  end
end

require 'assignment_logger'
require 'http_client'
require 'poller'
require 'config'
