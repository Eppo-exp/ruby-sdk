# frozen_string_literal: true

module EppoClient
  # configuration cache constants
  MAX_CACHE_ENTRIES = 1000 # arbitrary; the caching library requires a max limit

  # poller constants
  SECOND_MILLIS = 1000
  MINUTE_MILLIS = 60 * SECOND_MILLIS
  POLL_JITTER_MILLIS = 30 * SECOND_MILLIS
  POLL_INTERVAL_MILLIS = 5 * MINUTE_MILLIS

  # the configs endpoint
  RAC_ENDPOINT = 'randomized_assignment/v2/config'
end
