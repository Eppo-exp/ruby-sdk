# frozen_string_literal: true

require 'webmock/rspec'

require 'client'
require 'eppo_client'
require 'config'
require 'assignment_logger'
require 'configuration_requestor'
require 'shard'
require 'rules'

test_data = []
Dir.foreach('spec/test-data/assignment-v2') do |file_name|
  next if ['.', '..'].include?(file_name)

  file = File.open("spec/test-data/assignment-v2/#{file_name}")
  test_case_dict = JSON.parse(file.read)
  test_data.push(test_case_dict)
  file.close
end

MOCK_BASE_URL = 'http://localhost:4001/api'

# rubocop:disable Metrics/BlockLength
describe EppoClient::Client do
  before(:each) do
    stub_request(
      :get,
      "#{MOCK_BASE_URL}/randomized_assignment/v3/config?apiKey=dummy&sdkName=ruby&sdkVersion=0.2.0"
    ).to_return(
      body: File.read('spec/test-data/rac-experiments-v3.json')
    )
    @client = EppoClient.init(
      EppoClient::Config.new(
        'dummy',
        base_url: MOCK_BASE_URL,
        assignment_logger: EppoClient::AssignmentLogger.new
      )
    )
    sleep(0.1)
  end

  after(:each) do
    @client.shutdown
  end

  it 'tests assigning a blank experiment' do
    expect { @client.get_assignment('subject-1', '') }.to raise_error(
      EppoClient::InvalidValueError, 'InvalidValueError: flag_key cannot be blank'
    )
  end

  it 'tests assigning a subject not in sample' do
    allocation = EppoClient::AllocationDto.new(
      0,
      [
        EppoClient::VariationDto.new(
          'control',
          'control',
          EppoClient::ShardRange.new(0, 10_000)
        )
      ]
    )
    mock_config_requestor = double('mock config requestor')
    allow(mock_config_requestor).to receive(:get_configuration).and_return(
      EppoClient::ExperimentConfigurationDto.new(
        {
          'subjectShards' => 10_000,
          'enabled' => true,
          'name' => 'recommendation_algo',
          'overrides' => {},
          'allocations' => { 'allocation' => allocation }
        }
      )
    )
    allow(mock_config_requestor).to receive(:fetch_and_store_configurations)
    client = EppoClient.initialize_client(mock_config_requestor, EppoClient::AssignmentLogger.new)
    expect(client.get_assignment('user-1', 'experiment-key-1')).to be_nil
  end

  it 'tests log assignment' do
    allocation = EppoClient::AllocationDto.new(
      1,
      [
        EppoClient::VariationDto.new(
          'control',
          'control',
          EppoClient::ShardRange.new(0, 10_000)
        )
      ]
    )
    mock_config_requestor = double('mock config requestor')
    exp_config = EppoClient::ExperimentConfigurationDto.new(
      {
        'subjectShards' => 10_000,
        'enabled' => true,
        'name' => 'recommendation_algo',
        'overrides' => {},
        'allocations' => { 'allocation' => allocation },
        'rules' => [EppoClient::Rule.new(
          conditions: [], allocation_key: 'allocation'
        )]
      }
    )
    allow(mock_config_requestor).to receive(:get_configuration).and_return(exp_config)
    allow(mock_config_requestor).to receive(:fetch_and_store_configurations)
    mock_logger = double('mock logger')
    allow(mock_logger).to receive(:log_assignment)
    client = EppoClient.initialize_client(mock_config_requestor, mock_logger)
    expect(mock_logger).to receive(:log_assignment).once
    expect(client.get_assignment('user-1', 'experiment-key-1')).to eq('control')
  end

  it 'tests get assignment handles logging exception' do
    allocation = EppoClient::AllocationDto.new(
      1,
      [
        EppoClient::VariationDto.new(
          'control',
          'control',
          EppoClient::ShardRange.new(0, 10_000)
        )
      ]
    )
    mock_config_requestor = double('mock config requestor')
    exp_config = EppoClient::ExperimentConfigurationDto.new(
      {
        'subjectShards' => 10_000,
        'enabled' => true,
        'name' => 'recommendation_algo',
        'overrides' => {},
        'allocations' => { 'allocation' => allocation },
        'rules' => [EppoClient::Rule.new(
          conditions: [], allocation_key: 'allocation'
        )]
      }
    )
    allow(mock_config_requestor).to receive(:get_configuration).and_return(exp_config)
    allow(mock_config_requestor).to receive(:fetch_and_store_configurations)
    mock_logger = double('mock logger')
    allow(mock_logger).to receive(:log_assignment).and_raise('logging error')
    client = EppoClient.initialize_client(mock_config_requestor, mock_logger)
    expect(client.get_assignment('user-1', 'experiment-key-1', {}, Logger::FATAL)).to eq('control')
  end

  it 'tests assign subject with with attributes and rules' do
    allocation = EppoClient::AllocationDto.new(
      1,
      [
        EppoClient::VariationDto.new(
          'control',
          'control',
          EppoClient::ShardRange.new(0, 10_000)
        )
      ]
    )
    matches_email_condition = EppoClient::Condition.new(
      operator: EppoClient::OperatorType::MATCHES,
      value: '.*@eppo.com',
      attribute: 'email'
    )
    text_rule = EppoClient::Rule.new(allocation_key: 'allocation', conditions: [matches_email_condition])
    mock_config_requestor = double('mock config requestor')
    exp_config = EppoClient::ExperimentConfigurationDto.new(
      {
        'subjectShards' => 10_000,
        'enabled' => true,
        'name' => 'experiment-key-1',
        'overrides' => {},
        'allocations' => { 'allocation' => allocation },
        'rules' => [text_rule]
      }
    )
    allow(mock_config_requestor).to receive(:get_configuration).and_return(exp_config)
    allow(mock_config_requestor).to receive(:fetch_and_store_configurations)
    client = EppoClient.initialize_client(mock_config_requestor, EppoClient::AssignmentLogger.new)
    expect(client.get_assignment('user-1', 'experiment-key-1')).to be_nil
    expect(
      client.get_assignment('user-1', 'experiment-key-1', { 'email' => 'test@example.com' })
    ).to be_nil
    expect(
      client.get_assignment('user1', 'experiment-key-1', { 'email' => 'test@eppo.com' })
    ).to eq('control')
  end

  it 'tests with subject in overrides' do
    allocation = EppoClient::AllocationDto.new(
      1,
      [
        EppoClient::VariationDto.new(
          'control',
          'control',
          EppoClient::ShardRange.new(0, 10_000)
        )
      ]
    )
    mock_config_requestor = double('mock config requestor')
    exp_config = EppoClient::ExperimentConfigurationDto.new(
      {
        'subjectShards' => 10_000,
        'enabled' => true,
        'name' => 'recommendation_algo',
        'overrides' => { 'd6d7705392bc7af633328bea8c4c6904' => 'override-variation' },
        'allocations' => { 'allocation' => allocation },
        'rules' => [EppoClient::Rule.new(
          conditions: [], allocation_key: 'allocation'
        )]
      }
    )
    allow(mock_config_requestor).to receive(:get_configuration).and_return(exp_config)
    allow(mock_config_requestor).to receive(:fetch_and_store_configurations)
    client = EppoClient.initialize_client(mock_config_requestor, EppoClient::AssignmentLogger.new)
    expect(client.get_assignment('user-1', 'experiment-key-1')).to eq('override-variation')
  end

  it 'tests with subject in overrides exp disabled' do
    allocation = EppoClient::AllocationDto.new(
      0,
      [
        EppoClient::VariationDto.new(
          'control',
          'control',
          EppoClient::ShardRange.new(0, 10_000)
        )
      ]
    )
    mock_config_requestor = double('mock config requestor')
    exp_config = EppoClient::ExperimentConfigurationDto.new(
      {
        'subjectShards' => 10_000,
        'enabled' => false,
        'name' => 'recommendation_algo',
        'overrides' => { 'd6d7705392bc7af633328bea8c4c6904' => 'override-variation' },
        'allocations' => { 'allocation' => allocation },
        'rules' => [EppoClient::Rule.new(
          conditions: [], allocation_key: 'allocation'
        )]
      }
    )
    allow(mock_config_requestor).to receive(:get_configuration).and_return(exp_config)
    allow(mock_config_requestor).to receive(:fetch_and_store_configurations)
    client = EppoClient.initialize_client(mock_config_requestor, EppoClient::AssignmentLogger.new)
    expect(client.get_assignment('user-1', 'experiment-key-1')).to eq('override-variation')
  end

  it 'tests with null experiment config' do
    mock_config_requestor = double('mock config requestor')
    allow(mock_config_requestor).to receive(:get_configuration)
    allow(mock_config_requestor).to receive(:fetch_and_store_configurations)
    client = EppoClient.initialize_client(mock_config_requestor, EppoClient::AssignmentLogger.new)
    expect(client.get_assignment('user-1', 'experiment-key-1')).to be_nil
  end

  test_data.each do |test_case|
    it 'tests assign subject in sample' do
      puts "---- Test case for #{test_case['experiment']} Experiment"
      client = EppoClient::Client.instance
      get_typed_assignment = {
        'string' => client.method(:get_assignment),
        'numeric' => client.method(:get_assignment),
        'boolean' => client.method(:get_assignment),
        'json' => client.method(:get_assignment)
      }[test_case['valueType']]
      assignments = []
      test_case.fetch('subjects', []).each do |subject_key|
        assignments.push(get_typed_assignment.call(subject_key, test_case['experiment']))
      end
      test_case.fetch('subjectsWithAttributes', []).each do |subject|
        assignments.push(
          get_typed_assignment.call(
            subject['subjectKey'], test_case['experiment'], subject['subjectAttributes']
          )
        )
      end
      expect(assignments).to eq(test_case['expectedAssignments'])
    end
  end
end
# rubocop:enable Metrics/BlockLength
