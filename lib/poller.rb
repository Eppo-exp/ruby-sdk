# frozen_string_literal: true

require 'concurrent/atom'
require 'sdk_logger'

# The poller
module EppoClient
  # The poller class invokes a callback and waits on repeat on a separate thread
  class Poller
    def initialize(interval_millis, jitter_millis, callback)
      @jitter_millis = jitter_millis
      @interval = interval_millis
      @stopped = Concurrent::Atom.new(false)
      @callback = callback
      @thread = nil
    end

    def start
      @stopped.reset(false)
      @thread = Thread.new { poll }
    end

    def stop
      @stopped.reset(true)
      Thread.kill(@thread)
    end

    def stopped?
      @stopped.value
    end

    def poll
      until stopped?
        begin
          @callback.call
        rescue StandardError => e
          EppoClient.logger('err').error("Unexpected error running poll task: #{e}")
          break
        end
        _wait_for_interval
      end
    end

    def _wait_for_interval
      interval_with_jitter = @interval - rand(@jitter_millis)
      sleep interval_with_jitter / 1000
    end
  end
end
