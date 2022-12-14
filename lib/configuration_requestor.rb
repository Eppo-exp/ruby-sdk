# frozen_string_literal: true

require 'logger'

# VariationDto class
class VariationDto
  attr_accessor :name, :value, :shard_range

  def initialize(name:, value:, shard_range:)
    @name = name
    @value = value
    @shard_range = shard_range
  end
end

# AllocationDto class
class AllocationDto
  attr_accessor :percent_exposure, :variations

  def initialize(percent_exposure:, variations:)
    @percent_exposure = percent_exposure
    @variations = variations
  end
end

# ExperimentConfigurationDto class
class ExperimentConfigurationDto
  attr_accessor :subject_shards, :enabled, :name, :overrides, :rules, :allocations

  def initialize(exp_config)
    @subject_shards = exp_config['subjectShards']
    @enabled = exp_config['enabled']
    @name = exp_config['name'] || nil
    @overrides = exp_config['overrides'] || {}
    @rules = exp_config['rules'] || []
    @allocations = exp_config['allocations']
  end
end

RAC_ENDPOINT = 'randomized_assignment/v2/config'

# HTTP Request Error class
class UnauthorizedError < StandardError
  def initialize(message)
    super("Unauthorized: #{message}")
  end
end

# Configuration requestor
module EppoClient
  @logger = Logger.new($stderr)

  def self.logger
    @logger
  end

  # ExperimentConfigurationRequestor
  class ExperimentConfigurationRequestor
    def initialize(http_client, config_store)
      @http_client = http_client
      @config_store = config_store
    end

    def get_configuration(experiment_key)
      @http_client.is_unauthorized && raise(UnauthorizedError, 'please check your API key')

      @config_store.retrieve_configuration(experiment_key)
    end

    def fetch_and_store_configurations
      configs = {}
      begin
        exp_configs = @http_client.get(RAC_ENDPOINT).fetch('flags', {})
        exp_configs.each { |exp_key, exp_config| configs[exp_key] = ExperimentConfigurationDto.new(exp_config) }
        @config_store.assign_configurations(configs)
      rescue StandardError => e
        EppoClient.logger.error("Error retrieving assignment configurations: #{e}")
      end
      configs
    end
  end
end
