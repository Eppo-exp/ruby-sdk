# frozen_string_literal: true

require 'sdk_logger'
require 'custom_errors'
require 'constants'

module EppoClient
  # A class for the variation object
  class VariationDto
    attr_reader :name, :value, :shard_range

    def initialize(name, value, shard_range)
      @name = name
      @value = value
      @shard_range = shard_range
    end
  end

  # A class for the allocation object
  class AllocationDto
    attr_reader :percent_exposure, :variations

    def initialize(percent_exposure, variations)
      @percent_exposure = percent_exposure
      @variations = variations
    end
  end

  # A class for the experiment configuration object
  class ExperimentConfigurationDto
    attr_reader :subject_shards, :enabled, :name, :overrides, :rules, :allocations

    def initialize(exp_config)
      @subject_shards = exp_config['subjectShards']
      @enabled = exp_config['enabled']
      @name = exp_config['name'] || nil
      @overrides = exp_config['overrides'] || {}
      @rules = exp_config['rules'] || []
      @allocations = exp_config['allocations']
    end
  end

  # The class for requesting experiment configs
  class ExperimentConfigurationRequestor

    attr_reader :config_store

    def initialize(http_client, config_store)
      @http_client = http_client
      @config_store = config_store
    end

    def get_configuration(experiment_key)
      @http_client.is_unauthorized && raise(EppoClient::UnauthorizedError, 'please check your API key')
      @config_store.retrieve_configuration(experiment_key)
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def fetch_and_store_configurations
      configs = {}
      begin
        exp_configs = @http_client.get(EppoClient::RAC_ENDPOINT).fetch('flags', {})
        exp_configs.each do |exp_key, exp_config|
          exp_config['allocations'].each do |k, v|
            exp_config['allocations'][k] = EppoClient::AllocationDto.new(
              v['percentExposure'],
              v['variations'].map do |var|
                EppoClient::VariationDto.new(
                  var['name'],
                  var['value'],
                  EppoClient::ShardRange.new(var['shardRange']['start'], var['shardRange']['end'])
                )
              end
            )
          end
          exp_config['rules'] = exp_config['rules'].map do |rule|
            EppoClient::Rule.new(
              conditions: rule['conditions'].map do |condition|
                EppoClient::Condition.new(
                  value: condition['value'],
                  operator: condition['operator'],
                  attribute: condition['attribute']
                )
              end,
              allocation_key: rule['allocationKey']
            )
          end
          configs[exp_key] = EppoClient::ExperimentConfigurationDto.new(exp_config)
        end
        @config_store.assign_configurations(configs)
      rescue EppoClient::HttpRequestError => e
        EppoClient.logger('err').error("Error retrieving assignment configurations: #{e}")
      end
      configs
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  end
end
