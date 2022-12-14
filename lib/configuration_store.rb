# frozen_string_literal: true

require 'concurrent/atomic/read_write_lock'

module EppoClient
  # Configuration store
  class ConfigurationStore
    attr_reader :lock

    def initialize(max_size)
      @cache = EppoClient::LRUCache.new(max_size)
      @lock = Concurrent::ReadWriteLock.new
    end

    def retrieve_configuration(key)
      @lock.with_read_lock { @cache[key] }
    end

    def assign_configurations(configs)
      @lock.with_write_lock do
        configs.each do |key, config|
          @cache[key] = config
        end
      end
    end
  end
end

require 'lru_cache'
