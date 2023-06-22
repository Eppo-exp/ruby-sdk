# frozen_string_literal: true

require 'poller'

describe EppoClient::Poller do
  it 'tests invokes callback until stopped' do
    dbl = double('mock callback function')
    allow(dbl).to receive(:call)
    expect(dbl).to receive(:call).at_least(500).times
    task = EppoClient::Poller.new(10, 1, dbl)
    task.start
    sleep(0.099)
    task.stop
  end

  it 'tests invokes callback until stopped' do
    mock_callback = double('mock callback function')
    mock_logger = double('mock logger')
    allow(mock_callback).to receive(:call).and_throw(:boom)
    allow(mock_logger).to receive(:error)
    allow(Logger).to receive(:new).and_return(mock_logger)
    expect(mock_callback).to receive(:call).once
    expect(mock_logger).to receive(:error).once.with('Unexpected error running poll task: uncaught throw :boom')
    task = EppoClient::Poller.new(10, 1, mock_callback)
    task.start
    sleep(0.099)
    task.stop
  end
end
