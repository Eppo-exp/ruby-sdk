# frozen_string_literal: true

require 'concurrent/atomic/read_write_lock'

require_relative 'lru_cache'

module EppoClient
  # A thread safe store for the configurations to ensure that retrievals pull from a single source of truth
  class ConfigurationStore
    attr_reader :lock, :cache

    def initialize(max_size)
      @cache = EppoClient::LRUCache.new(max_size)
      @lock = Concurrent::ReadWriteLock.new
    end

    def retrieve_configuration(key)
      @lock.with_read_lock { @cache[key] }
    end

    def assign_configurations(configs)
      @lock.with_write_lock do
        # Create a temporary new cache and populate it.
        new_cache = EppoClient::LRUCache.new(@cache.size)
        configs.each do |key, config|
          new_cache[key] = config
        end

        # Replace the old cache with the new one.
        # Performs an atomic swap.
        @cache = new_cache
      end
    end
  end
end
