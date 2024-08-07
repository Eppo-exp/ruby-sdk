# frozen_string_literal: true

module EppoClient
  # The LRU cache relies on the fact that Ruby's Hash class maintains insertion order. So deleting
  # and re-inserting a key-value pair on access moves the key to the last position. When an
  # entry is added and the cache is full, the first entry is removed.
  class LRUCache
    attr_reader :cache, :size

    # Creates a new LRUCache that can hold +size+ entries.
    def initialize(size)
      @size = size
      @cache = {}
    end

    # Returns the stored value for +key+ or +nil+ if no value was stored under the key.
    def [](key)
      (val = @cache.delete(key)).nil? ? nil : @cache[key] = val
    end

    # Stores the +value+ under the +key+.
    def []=(key, value)
      @cache.delete(key)
      @cache[key] = value
      @cache.shift if @cache.length > @size
    end
  end
end
