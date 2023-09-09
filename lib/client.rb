# frozen_string_literal: true

require 'singleton'
require 'time'

require 'constants'
require 'custom_errors'
require 'rules'
require 'shard'
require 'validation'
require 'variation_type'

module EppoClient
  # The main client singleton
  # rubocop:disable Metrics/ClassLength
  class Client
    extend Gem::Deprecate
    include Singleton
    attr_accessor :config_requestor, :assignment_logger, :poller

    def instance
      Client.instance
    end

    def get_string_assignment(
      subject_key,
      flag_key,
      subject_attributes = {},
      log_level = EppoClient::DEFAULT_LOGGER_LEVEL
    )
      logger = Logger.new($stdout)
      logger.level = log_level
      assigned_variation = get_assignment_variation(
        subject_key, flag_key, subject_attributes,
        EppoClient::VariationType::STRING_TYPE, logger
      )
      assigned_variation&.typed_value
    end

    def get_numeric_assignment(
      subject_key,
      flag_key,
      subject_attributes = {},
      log_level = EppoClient::DEFAULT_LOGGER_LEVEL
    )
      logger = Logger.new($stdout)
      logger.level = log_level
      assigned_variation = get_assignment_variation(
        subject_key, flag_key, subject_attributes,
        EppoClient::VariationType::NUMERIC_TYPE, logger
      )
      assigned_variation&.typed_value
    end

    def get_boolean_assignment(
      subject_key,
      flag_key,
      subject_attributes = {},
      log_level = EppoClient::DEFAULT_LOGGER_LEVEL
    )
      logger = Logger.new($stdout)
      logger.level = log_level
      assigned_variation = get_assignment_variation(
        subject_key, flag_key, subject_attributes,
        EppoClient::VariationType::BOOLEAN_TYPE, logger
      )
      assigned_variation&.typed_value
    end

    def get_parsed_json_assignment(
      subject_key,
      flag_key,
      subject_attributes = {},
      log_level = EppoClient::DEFAULT_LOGGER_LEVEL
    )
      logger = Logger.new($stdout)
      logger.level = log_level
      assigned_variation = get_assignment_variation(
        subject_key, flag_key, subject_attributes,
        EppoClient::VariationType::JSON_TYPE, logger
      )
      assigned_variation&.typed_value
    end

    def get_json_string_assignment(
      subject_key,
      flag_key,
      subject_attributes = {},
      log_level = EppoClient::DEFAULT_LOGGER_LEVEL
    )
      logger = Logger.new($stdout)
      logger.level = log_level
      assigned_variation = get_assignment_variation(
        subject_key, flag_key, subject_attributes,
        EppoClient::VariationType::JSON_TYPE, logger
      )
      assigned_variation&.value
    end

    def get_assignment(
      subject_key,
      flag_key,
      subject_attributes = {},
      log_level = EppoClient::DEFAULT_LOGGER_LEVEL
    )
      logger = Logger.new($stdout)
      logger.level = log_level
      assigned_variation = get_assignment_variation(subject_key, flag_key,
                                                    subject_attributes, nil,
                                                    logger)
      assigned_variation&.value
    end
    deprecate :get_assignment, 'the get_<typed>_assignment methods', 2024, 1

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    def get_assignment_variation(
      subject_key,
      flag_key,
      subject_attributes,
      expected_variation_type,
      logger
    )
      EppoClient.validate_not_blank('subject_key', subject_key)
      EppoClient.validate_not_blank('flag_key', flag_key)
      experiment_config = @config_requestor.get_configuration(flag_key)
      override = get_subject_variation_override(experiment_config, subject_key)
      unless override.nil?
        unless expected_variation_type.nil?
          variation_is_expected_type =
            EppoClient::VariationType.expected_type?(
              override, expected_variation_type
            )
          return nil unless variation_is_expected_type
        end
        return override
      end

      if experiment_config.nil? || experiment_config.enabled == false
        logger.debug(
          '[Eppo SDK] No assigned variation. No active experiment or flag for '\
          "key: #{flag_key}"
        )
        return nil
      end

      matched_rule = EppoClient.find_matching_rule(subject_attributes, experiment_config.rules)
      if matched_rule.nil?
        logger.debug(
          '[Eppo SDK] No assigned variation. Subject attributes do not match '\
          "targeting rules: #{subject_attributes}"
        )
        return nil
      end

      allocation = experiment_config.allocations[matched_rule.allocation_key]
      unless in_experiment_sample?(
        subject_key,
        flag_key,
        experiment_config.subject_shards,
        allocation.percent_exposure
      )
        logger.debug(
          '[Eppo SDK] No assigned variation. Subject is not part of experiment'\
          ' sample population'
        )
        return nil
      end

      shard = EppoClient.get_shard(
        "assignment-#{subject_key}-#{flag_key}", experiment_config.subject_shards
      )
      assigned_variation = allocation.variations.find do |var|
        var.shard_range.shard_in_range?(shard)
      end

      assigned_variation_value_to_log = nil
      unless assigned_variation.nil?
        assigned_variation_value_to_log = assigned_variation.value
        unless expected_variation_type.nil?
          variation_is_expected_type = EppoClient::VariationType.expected_type?(
            assigned_variation, expected_variation_type
          )
          return nil unless variation_is_expected_type
        end
      end

      assignment_event = {
        "allocation": matched_rule.allocation_key,
        "experiment": "#{flag_key}-#{matched_rule.allocation_key}",
        "featureFlag": flag_key,
        "variation": assigned_variation_value_to_log,
        "subject": subject_key,
        "timestamp": Time.now.utc.iso8601,
        "subjectAttributes": subject_attributes
      }

      begin
        @assignment_logger.log_assignment(assignment_event)
      rescue EppoClient::AssignmentLoggerError => e
        # Error means log_assignment was not set up. This is okay to ignore.
      rescue StandardError => e
        logger.error("[Eppo SDK] Error logging assignment event: #{e}")
      end

      assigned_variation
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

    def shutdown
      @poller.stop
    end

    # rubocop:disable Metrics/MethodLength
    def get_subject_variation_override(experiment_config, subject)
      subject_hash = Digest::MD5.hexdigest(subject.to_s)
      if experiment_config&.overrides &&
         experiment_config.overrides[subject_hash] &&
         experiment_config.typed_overrides[subject_hash]
        EppoClient::VariationDto.new(
          'override',
          experiment_config.overrides[subject_hash],
          experiment_config.typed_overrides[subject_hash],
          EppoClient::ShardRange.new(0, 1000)
        )
      end
    end
    # rubocop:enable Metrics/MethodLength

    def in_experiment_sample?(subject, experiment_key, subject_shards,
                              percent_exposure)
      shard = EppoClient.get_shard("exposure-#{subject}-#{experiment_key}",
                                   subject_shards)
      shard <= percent_exposure * subject_shards
    end
  end
  # rubocop:enable Metrics/ClassLength
end
