# frozen_string_literal: true

require 'digest'

# The helper for sharding logic
module EppoClient
  # ShardRange
  class ShardRange
    attr_reader :start, :end

    def initialize(range_start, range_end)
      @start = range_start
      @end = range_end
    end

    def shard_in_range?(shard)
      shard >= @start && shard < @end
    end
  end

  def get_shard(input, subject_shards)
    hash_output = Digest::MD5.hexdigest(input)
    # get the first 4 bytes of the md5 hex string and parse it using base 16
    # (8 hex characters represent 4 bytes, e.g. 0xffffffff represents the max 4-byte integer)
    int_from_hash = hash_output[0...8].to_i(16)
    int_from_hash % subject_shards
  end

  module_function :get_shard
end