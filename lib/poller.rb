# frozen_string_literal: true

module EppoClient
  # The HTTP Client
  class Poller
    def initialize(interval_millis, jitter_millis, callback)
      @jitter_millis = jitter_millis
      @interval = interval_millis
      @stop_event = Thread::Event.new
      @callback = callback
      @thread = Thread.new { poll }
      @thread.daemon = true
    end

    def start
      @thread.start
    end

    def stop
      @stop_event.set
    end

    def stopped?
      @stop_event.set?
    end

    def poll
      until stopped?
        begin
          @callback.call
        rescue StandardError => e
          logger.error("Unexpected error running poll task: #{e}")
          break
        end
        _wait_for_interval
      end
    end

    def _wait_for_interval
      interval_with_jitter = @interval - rand(@jitter_millis)
      @stop_event.wait(interval_with_jitter / 1000)
    end
  end
end
