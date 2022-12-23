# frozen_string_literal: true

require 'faraday'
require 'faraday/retry'

REQUEST_TIMEOUT_SECONDS = 2
# This applies only to failed DNS lookups and connection timeouts,
# never to requests where data has made it to the server.
MAX_RETRIES = 3

module EppoClient
  # The SDK params object
  class SdkParams
    attr_reader :api_key, :sdk_name, :sdk_version

    def initialize(api_key, sdk_name, sdk_version)
      @api_key = api_key
      @sdk_name = sdk_name
      @sdk_version = sdk_version
    end

    # attributes are camelCase because that's what the backend endpoint expects
    def formatted
      {
        'apiKey' => api_key,
        'sdkName' => sdk_name,
        'sdkVersion' => sdk_version
      }
    end

    # Hide instance variables (specifically api_key) from logs
    def inspect
      "#<EppoClient::SdkParams:#{object_id}>"
    end
  end

  # The http request client with retry/timeout behavior
  class HttpClient
    attr_reader :is_unauthorized

    @retry_options = {
      max: MAX_RETRIES,
      interval: 0.05,
      interval_randomness: 0.5,
      backoff_factor: 2,
      exceptions: ['Timeout::Error']
    }

    def initialize(base_url, sdk_params)
      @base_url = base_url
      @sdk_params = sdk_params
      @is_unauthorized = false
    end

    def get(resource)
      conn = Faraday::Connection.new(@base_url, params: @sdk_params) do |f|
        f.request :retry, @retry_options
      end
      conn.options.timeout = REQUEST_TIMEOUT_SECONDS
      response = conn.get(resource)
      @is_unauthorized = response.status == 401
      raise get_http_error(response.status, resource) if response.status != 200

      JSON.parse(response.body)
    end

    private

    def get_http_error(status_code, resource)
      EppoClient::HttpRequestError.new("HTTP #{status_code} error while requesting resource #{resource}", status_code)
    end
  end
end

require 'custom_errors'
