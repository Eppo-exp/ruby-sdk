# frozen_string_literal: true

require 'singleton'

# This module scopes all the client SDK's classes and functions
module EppoClient
  @sdk_version = '1.1.1'
  @client = nil

  def initialize_client(config_requestor, assignment_logger)
    !@client.nil? && @client.shutdown
    @client = EppoClient::Client.instance
    @client.config_requestor = config_requestor
    @client.assignment_logger = assignment_logger
    @client.poller = EppoClient::Poller.new(
      EppoClient::POLL_INTERVAL_MILLIS,
      EppoClient::POLL_JITTER_MILLIS,
      proc { config_requestor.fetch_and_store_configurations }
    )
  end

  # rubocop:disable Metrics/MethodLength
  def init(config)
    config.validate
    sdk_params = EppoClient::SdkParams.new(config.api_key, 'ruby', @sdk_version)
    http_client = EppoClient::HttpClient.new(config.base_url, sdk_params.formatted)
    config_store = EppoClient::ConfigurationStore.new(EppoClient::MAX_CACHE_ENTRIES)
    config_store.lock.with_write_lock do
      EppoClient.initialize_client(
        EppoClient::ExperimentConfigurationRequestor.new(http_client, config_store),
        EppoClient::AssignmentLogger.new
      )
    end
    @client
  end
  # rubocop:enable Metrics/MethodLength

  module_function :init, :initialize_client
end

require 'assignment_logger'
require 'http_client'
require 'poller'
require 'config'
require 'client'
require 'constants'
require 'configuration_requestor'
require 'configuration_store'