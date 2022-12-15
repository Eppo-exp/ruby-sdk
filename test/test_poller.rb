# frozen_string_literal: true

require 'minitest/autorun'
require 'poller'

class PollerTest < Minitest::Test
  def test_invokes_callback_until_stopped
    mock = Minitest::Mock.new
    mock.expect :call, nil

    task = EppoClient::Poller.new(10, 1, mock)
    task.start
    sleep 0.099
    task.stop
    assert_mock mock
  end
end
