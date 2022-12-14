# frozen_string_literal: true

module EppoClient
  # The main client singleton
  class Client
    include Singleton
    attr_accessor :config_requestor, :assignment_logger, :poller

    def instance
      Client.instance
    end

    def get_assignment(subject_key, flag_key, subject_attributes)
      EppoClient.validate_not_blank('subject_key', subject_key)
      EppoClient.validate_not_blank('flag_key', flag_key)
      experiment_config = @config_requestor.get_configuration(flag_key)
      override = get_subject_variation_override(experiment_config, subject_key)
      unless override.nil?
        return override 
      end

      if (experiment_config.nil? || experiment_config.enabled == false)
        puts "[Eppo SDK] No assigned variation. No active experiment or flag for key: #{flag_key}"
        return nil
      end

      matched_rule = EppoClient::find_matching_rule(subject_attributes, experiment_config.rules)
      if matched_rule.nil?
        puts "[Eppo SDK] No assigned variation. Subject attributes do not match targeting rules: #{subject_attributes}"
        return nil
      end

      allocation = experiment_config.allocations[matched_rule.allocation_key]
      unless in_experiment_sample?(subject_key, flag_key, experiment_config.subject_shards, allocation.percent_exposure)
        puts '[Eppo SDK] No assigned variation. Subject is not part of experiment sample population'
        return nil
      end

      shard = EppoClient::get_shard("exposure-#{subject}-#{flag_key}", experiment_config.subject_shards)
      assigned_variation = allocation.variations.find do |variation| 
        EppoClient::ShardRange.new(
          variation.shard_range.start, 
          variation.shard_range.end
        ).shard_in_range?(shard) 
      end&.value

      assignment_event = {
        "experiment": flag_key,
        "variation": assigned_variation,
        "subject": subject_key,
        "timestamp": Time.now.utc.iso8601,
        "subjectAttributes": subject_attributes,
      }

      begin
        @assignment_logger.log_assignment(assignment_event)
      rescue => e
        puts "[Eppo SDK] Error logging assignment event: #{e}"
      end

      assigned_variation
    end

    def shutdown
      @poller.stop
    end

    def get_subject_variation_override(experiment_config, subject)
      subject_hash = Digest::MD5.hexdigest(subject)
      if experiment_config && experiment_config.overrides.include?(subject_hash)
        return experiment_config.overrides[subject_hash]
      end
    end

    def in_experiment_sample?(subject, experiment_key, subject_shards, percent_exposure)
      shard = EppoClient::get_shard("exposure-#{subject}-#{experiment_key}", subject_shards)
      shard <= percent_exposure * subject_shards
    end    
  end
end

require 'validation'
require 'rules'
require 'shard'