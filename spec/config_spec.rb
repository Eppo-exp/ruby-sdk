# frozen_string_literal: true

require 'config'

describe EppoClient::Config do
  it 'tests config object will not show the api_key in logs' do
    config = EppoClient::Config.new(
      'asdfghqwerty',
      base_url: 'http://localhost:4000/api'
    )
    expect(config.inspect).to match(/#<EppoClient::Config:.+/)
    expect(config.inspect).not_to match(/.*@api_key=".*/)
  end
end
