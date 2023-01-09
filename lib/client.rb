# frozen_string_literal: true

require 'singleton'
require 'time'

require 'constants'
require 'custom_errors'
require 'rules'
require 'sdk_logger'
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

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    def get_assignment(
      subject_key,
      flag_or_experiment_key,
      subject_attributes = {},
      log_level = EppoClient::DEFAULT_LOGGER_LEVEL
    )
      EppoClient.logger.level = log_level
      EppoClient.validate_not_blank('subject_key', subject_key)
      EppoClient.validate_not_blank('flag_or_experiment_key', flag_or_experiment_key)
      experiment_config = @config_requestor.get_configuration(flag_or_experiment_key)
      override = get_subject_variation_override(experiment_config, subject_key)
      return override unless override.nil?

      if experiment_config.nil? || experiment_config.enabled == false
        EppoClient.logger.debug(
          "[Eppo SDK] No assigned variation. No active experiment or flag for key: #{flag_or_experiment_key}"
        )
        return nil
      end

      matched_rule = EppoClient.find_matching_rule(subject_attributes, experiment_config.rules)
      if matched_rule.nil?
        EppoClient.logger.debug(
          "[Eppo SDK] No assigned variation. Subject attributes do not match targeting rules: #{subject_attributes}"
        )
        return nil
      end

      allocation = experiment_config.allocations[matched_rule.allocation_key]
      unless in_experiment_sample?(
        subject_key,
        flag_or_experiment_key,
        experiment_config.subject_shards,
        allocation.percent_exposure
      )
        EppoClient.logger.debug(
          '[Eppo SDK] No assigned variation. Subject is not part of experiment sample population'
        )
        return nil
      end

      shard = EppoClient.get_shard("assignment-#{subject_key}-#{flag_or_experiment_key}", experiment_config.subject_shards)
      assigned_variation = allocation.variations.find { |var| var.shard_range.shard_in_range?(shard) }.value

      assignment_event = {
        "experiment": flag_or_experiment_key,
        "variation": assigned_variation,
        "subject": subject_key,
        "timestamp": Time.now.utc.iso8601,
        "subjectAttributes": subject_attributes
      }

      begin
        @assignment_logger.log_assignment(assignment_event)
      rescue EppoClient::AssignmentLoggerError => e
        # This error means that log_assignment was not set up. This is okay to ignore.
      rescue StandardError => e
        EppoClient.logger.error("[Eppo SDK] Error logging assignment event: #{e}")
      end

      assigned_variation
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

    def shutdown
      @poller.stop
    end

    def get_subject_variation_override(experiment_config, subject)
      subject_hash = Digest::MD5.hexdigest(subject.to_s)
      experiment_config&.overrides && experiment_config.overrides[subject_hash]
    end

    def in_experiment_sample?(subject, experiment_key, subject_shards, percent_exposure)
      shard = EppoClient.get_shard("exposure-#{subject}-#{experiment_key}", subject_shards)
      shard <= percent_exposure * subject_shards
    end
  end
end
