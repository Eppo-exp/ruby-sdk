# frozen_string_literal: true

require 'eppo_client/rules'

greater_than_condition = EppoClient::Condition.new(operator: EppoClient::OperatorType::GT, value: 10, attribute: 'age')
less_than_condition = EppoClient::Condition.new(operator: EppoClient::OperatorType::LT, value: 100, attribute: 'age')
numeric_rule = EppoClient::Rule.new(
  allocation_key: 'allocation',
  conditions: [less_than_condition, greater_than_condition]
)

matches_email_condition = EppoClient::Condition.new(
  operator: EppoClient::OperatorType::MATCHES, value: '.*@email.com', attribute: 'email'
)
text_rule = EppoClient::Rule.new(allocation_key: 'allocation', conditions: [matches_email_condition])
rule_with_empty_conditions = EppoClient::Rule.new(allocation_key: 'allocation', conditions: [])

# rubocop:disable Metrics/BlockLength
# rubocop:disable Layout/LineLength
describe EppoClient::Rule do
  it 'tests find_matching_rule_when_no_rules_match' do
    subject_attributes = { 'age' => 20, 'country' => 'US' }
    expect(EppoClient.find_matching_rule(subject_attributes, [])).to be_nil
  end

  it 'tests find matching rule when no rules match' do
    subject_attributes = { 'age' => 99, 'country' => 'US', 'email' => 'test@example.com' }
    expect(EppoClient.find_matching_rule(subject_attributes, [text_rule])).to be_nil
  end

  it 'tests find matching rule on match' do
    expect(EppoClient.find_matching_rule({ 'age' => 99 }, [numeric_rule])).to be(numeric_rule)
    expect(EppoClient.find_matching_rule({ 'email' => 'testing@email.com' }, [text_rule])).to be(text_rule)
  end

  it 'tests find matching rule if no attribute for condition' do
    expect(EppoClient.find_matching_rule({}, [numeric_rule])).to be_nil
  end

  it 'tests find matching rule if no conditions for rule' do
    expect(EppoClient.find_matching_rule({}, [rule_with_empty_conditions])).to be(rule_with_empty_conditions)
  end

  it 'tests find matching rule if numeric operator with string' do
    expect(EppoClient.find_matching_rule({ 'age' => '99' }, [numeric_rule])).to be_nil
  end

  it 'tests find matching rule for semver string' do
    semver_greater_than_condition = EppoClient::Condition.new(
      operator: EppoClient::OperatorType::GTE, value: '1.0.0', attribute: 'version'
    )
    semver_less_than_condition = EppoClient::Condition.new(
      operator: EppoClient::OperatorType::LTE, value: '2.0.0', attribute: 'version'
    )
    semver_rule = EppoClient::Rule.new(
      allocation_key: 'allocation',
      conditions: [semver_less_than_condition, semver_greater_than_condition]
    )

    expect(EppoClient.find_matching_rule({ 'version' => '1.1.0' }, [semver_rule])).to be(semver_rule)
    expect(EppoClient.find_matching_rule({ 'version' => '2.0.0' }, [semver_rule])).to be(semver_rule)
    expect(EppoClient.find_matching_rule({ 'version' => '2.1.0' }, [semver_rule])).to be_nil
  end

  it 'tests find matching rule for semver string, ensuring it is not interpreted lexographically' do
    semver_greater_than_condition = EppoClient::Condition.new(
      operator: EppoClient::OperatorType::GTE, value: '1.2.3', attribute: 'version'
    )

    semver_less_than_condition = EppoClient::Condition.new(
      operator: EppoClient::OperatorType::LTE, value: '1.15.0', attribute: 'version'
    )

    semver_rule = EppoClient::Rule.new(
      allocation_key: 'allocation',
      conditions: [semver_less_than_condition, semver_greater_than_condition]
    )

    expect(EppoClient.find_matching_rule({ 'version' => '1.12.0' }, [semver_rule])).to be(semver_rule)
  end

  it 'tests find matching rule with numeric value and regex' do
    condition = EppoClient::Condition.new(
      operator: EppoClient::OperatorType::MATCHES, value: '[0-9]+', attribute: 'age'
    )
    rule = EppoClient::Rule.new(allocation_key: 'allocation', conditions: [condition])
    expect(EppoClient.find_matching_rule({ 'age' => 99 }, [rule])).to be(rule)
  end

  it 'tests ONE_OF operator with boolean' do
    one_of_rule = EppoClient::Rule.new(
      allocation_key: 'allocation', conditions: [
        EppoClient::Condition.new(operator: EppoClient::OperatorType::ONE_OF, value: ['True'], attribute: 'enabled')
      ]
    )
    not_one_of_rule = EppoClient::Rule.new(
      allocation_key: 'allocation', conditions: [
        EppoClient::Condition.new(operator: EppoClient::OperatorType::NOT_ONE_OF, value: ['True'], attribute: 'enabled')
      ]
    )
    expect(EppoClient.find_matching_rule({ 'enabled' => true }, [one_of_rule])).to be(one_of_rule)
    expect(EppoClient.find_matching_rule({ 'enabled' => false }, [one_of_rule])).to be_nil
    expect(EppoClient.find_matching_rule({ 'enabled' => true }, [not_one_of_rule])).to be_nil
    expect(EppoClient.find_matching_rule({ 'enabled' => false }, [not_one_of_rule])).to be(not_one_of_rule)
  end

  it 'tests ONE_OF operator case insensitive' do
    one_of_rule = EppoClient::Rule.new(
      allocation_key: 'allocation', conditions: [
        EppoClient::Condition.new(
          operator: EppoClient::OperatorType::ONE_OF, value: %w[1Ab Ron], attribute: 'name'
        )
      ]
    )
    expect(EppoClient.find_matching_rule({ 'name' => 'ron' }, [one_of_rule])).to be(one_of_rule)
    expect(EppoClient.find_matching_rule({ 'name' => '1AB' }, [one_of_rule])).to be(one_of_rule)
  end

  it 'tests NOT_ONE_OF operator case insensitive' do
    not_one_of_rule = EppoClient::Rule.new(
      allocation_key: 'allocation', conditions: [
        EppoClient::Condition.new(
          operator: EppoClient::OperatorType::NOT_ONE_OF, value: %w[bbB 1.1.ab], attribute: 'name'
        )
      ]
    )
    expect(EppoClient.find_matching_rule({ 'name' => 'BBB' }, [not_one_of_rule])).to be_nil
    expect(EppoClient.find_matching_rule({ 'name' => '1.1.AB' }, [not_one_of_rule])).to be_nil
  end

  it 'tests ONE_OF operator with string' do
    one_of_rule = EppoClient::Rule.new(
      allocation_key: 'allocation', conditions: [
        EppoClient::Condition.new(
          operator: EppoClient::OperatorType::ONE_OF, value: %w[john ron], attribute: 'name'
        )
      ]
    )
    not_one_of_rule = EppoClient::Rule.new(
      allocation_key: 'allocation', conditions: [
        EppoClient::Condition.new(
          operator: EppoClient::OperatorType::NOT_ONE_OF, value: %w[ron], attribute: 'name'
        )
      ]
    )
    expect(EppoClient.find_matching_rule({ 'name' => 'john' }, [one_of_rule])).to be(one_of_rule)
    expect(EppoClient.find_matching_rule({ 'name' => 'ron' }, [one_of_rule])).to be(one_of_rule)
    expect(EppoClient.find_matching_rule({ 'name' => 'sam' }, [one_of_rule])).to be_nil
    expect(EppoClient.find_matching_rule({ 'name' => 'ron' }, [not_one_of_rule])).to be_nil
    expect(EppoClient.find_matching_rule({ 'name' => 'sam' }, [not_one_of_rule])).to be(not_one_of_rule)
  end

  it 'tests ONE_OF operator with number' do
    one_of_rule = EppoClient::Rule.new(
      allocation_key: 'allocation', conditions: [
        EppoClient::Condition.new(
          operator: EppoClient::OperatorType::ONE_OF, value: %w[14 15.11], attribute: 'number'
        )
      ]
    )
    not_one_of_rule = EppoClient::Rule.new(
      allocation_key: 'allocation', conditions: [
        EppoClient::Condition.new(
          operator: EppoClient::OperatorType::NOT_ONE_OF, value: %w[10], attribute: 'number'
        )
      ]
    )
    expect(EppoClient.find_matching_rule({ 'number' => '14' }, [one_of_rule])).to be(one_of_rule)
    expect(EppoClient.find_matching_rule({ 'number' => 15.11 }, [one_of_rule])).to be(one_of_rule)
    expect(EppoClient.find_matching_rule({ 'number' => '10' }, [one_of_rule])).to be_nil
    expect(EppoClient.find_matching_rule({ 'number' => '10' }, [not_one_of_rule])).to be_nil
    expect(EppoClient.find_matching_rule({ 'number' => 11 }, [not_one_of_rule])).to be(not_one_of_rule)
  end
end
# rubocop:enable Metrics/BlockLength
# rubocop:enable Layout/LineLength
