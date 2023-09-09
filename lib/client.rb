# frozen_string_literal: true

require 'singleton'
require 'time'

require 'constants'
require 'custom_errors'
require 'rules'
require 'shard'
require 'validation'

module EppoClient
  # The main client singleton
  class Client
    include Singleton
    attr_accessor :config_requestor, :assignment_logger, :poller

    def instance
      Client.instance
    end

    def get_assignment(
      subject_key,
      flag_key,
      subject_attributes = {},
      log_level = EppoClient::DEFAULT_LOGGER_LEVEL
    )
      logger = Logger.new($stdout)
      logger.level = log_level
      assigned_variation = get_assignment_variation(subject_key, flag_key, subject_attributes, logger)
      assigned_variation&.value
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
    def get_assignment_variation(
      subject_key,
      flag_key,
      subject_attributes,
      logger
    )
      EppoClient.validate_not_blank('subject_key', subject_key)
      EppoClient.validate_not_blank('flag_key', flag_key)
      experiment_config = @config_requestor.get_configuration(flag_key)
      override = get_subject_variation_override(experiment_config, subject_key)
      return override unless override.nil?

      if experiment_config.nil? || experiment_config.enabled == false
        logger.debug(
          "[Eppo SDK] No assigned variation. No active experiment or flag for key: #{flag_key}"
        )
        return nil
      end

      matched_rule = EppoClient.find_matching_rule(subject_attributes, experiment_config.rules)
      if matched_rule.nil?
        logger.debug(
          "[Eppo SDK] No assigned variation. Subject attributes do not match targeting rules: #{subject_attributes}"
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
          '[Eppo SDK] No assigned variation. Subject is not part of experiment sample population'
        )
        return nil
      end

      shard = EppoClient.get_shard("assignment-#{subject_key}-#{flag_key}", experiment_config.subject_shards)
      assigned_variation = allocation.variations.find { |var| var.shard_range.shard_in_range?(shard) }

      assignment_event = {
        "allocation": matched_rule.allocation_key,
        "experiment": "#{flag_key}-#{matched_rule.allocation_key}",
        "featureFlag": flag_key,
        "variation": assigned_variation.value,
        "subject": subject_key,
        "timestamp": Time.now.utc.iso8601,
        "subjectAttributes": subject_attributes
      }

      begin
        @assignment_logger.log_assignment(assignment_event)
      rescue EppoClient::AssignmentLoggerError => e
        # This error means that log_assignment was not set up. This is okay to ignore.
      rescue StandardError => e
        logger.error("[Eppo SDK] Error logging assignment event: #{e}")
      end

      assigned_variation
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

    def shutdown
      @poller.stop
    end

    def get_subject_variation_override(experiment_config, subject)
      subject_hash = Digest::MD5.hexdigest(subject.to_s)
      if experiment_config&.overrides && experiment_config.overrides[subject_hash] &&
         experiment_config.typed_overrides[subject_hash]
        EppoClient::VariationDto.new(
          'override',
          experiment_config.overrides[subject_hash],
          experiment_config.typed_overrides[subject_hash],
          EppoClient::ShardRange.new(0, 1000)
        )
      end
    end

    def in_experiment_sample?(subject, experiment_key, subject_shards, percent_exposure)
      shard = EppoClient.get_shard("exposure-#{subject}-#{experiment_key}", subject_shards)
      shard <= percent_exposure * subject_shards
    end
  end
end
