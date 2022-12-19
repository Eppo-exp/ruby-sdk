# frozen_string_literal: true

require 'configuration_requestor'
require 'configuration_store'

TEST_MAX_SIZE = 10

test_exp = EppoClient::ExperimentConfigurationDto.new(
  {
    subject_shards: 1000,
    enabled: true,
    name: 'randomization_algo',
    allocations: { 'allocation-1': EppoClient::AllocationDto.new(1, []) }
  }
)

store = EppoClient::ConfigurationStore.new(TEST_MAX_SIZE)

describe EppoClient::ConfigurationStore do
  it 'tests get configuration unknown key' do
    store.assign_configurations({ 'randomization_algo' => test_exp })
    expect(store.retrieve_configuration('unknown_exp')).to be_nil
  end

  it 'tests get configuration known key' do
    store.assign_configurations({ 'randomization_algo' => test_exp })
    expect(store.retrieve_configuration('randomization_algo')).to be(test_exp)
  end

  it 'tests evicts old entries when max size exceeded' do
    store.assign_configurations({ 'item_to_be_evicted' => test_exp})
    expect(store.retrieve_configuration('item_to_be_evicted')).to be(test_exp)
    configs = {}
    TEST_MAX_SIZE.times { |i| configs["test-entry-#{i}"] = test_exp }
    store.assign_configurations(configs)
    expect(store.retrieve_configuration('item_to_be_evicted')).to be_nil
    expect(store.retrieve_configuration("test-entry-#{TEST_MAX_SIZE - 1}")).to be(test_exp)
  end
end
