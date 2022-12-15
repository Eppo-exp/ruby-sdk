# frozen_string_literal: true

require 'minitest/autorun'
require 'config'

class ConfigTest < Minitest::Test
  def test_config_inspect
    config = EppoClient::Config.new(
      'asdfghqwerty',
      base_url: 'http://localhost:4000/api'
    )
    assert_match(/#<EppoClient::Config:.+/, config.inspect)
  end
end
