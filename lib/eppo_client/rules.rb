# frozen_string_literal: true

require 'semver'

# The helper module for rules
module EppoClient
  module OperatorType
    MATCHES = 'MATCHES'
    GTE = 'GTE'
    GT = 'GT'
    LTE = 'LTE'
    LT = 'LT'
    ONE_OF = 'ONE_OF'
    NOT_ONE_OF = 'NOT_ONE_OF'
  end

  # A class for the Condition object
  class Condition
    attr_accessor :operator, :attribute, :value

    def initialize(operator:, attribute:, value:)
      @operator = operator
      @attribute = attribute
      @value = value
    end
  end

  # A class for the Rule object
  class Rule
    attr_accessor :allocation_key, :conditions

    def initialize(allocation_key:, conditions:)
      @allocation_key = allocation_key
      @conditions = conditions
    end
  end

  def find_matching_rule(subject_attributes, rules)
    rules.each do |rule|
      return rule if matches_rule(subject_attributes, rule)
    end
    nil
  end

  def matches_rule(subject_attributes, rule)
    rule.conditions.each do |condition|
      return false unless evaluate_condition(subject_attributes, condition)
    end
    true
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def evaluate_condition(subject_attributes, condition)
    subject_value = subject_attributes[condition.attribute]
    return false if subject_value.nil?

    case condition.operator
    when OperatorType::MATCHES
      !!(Regexp.new(condition.value) =~ subject_value.to_s)
    when OperatorType::ONE_OF
      condition.value.map(&:downcase).include?(subject_value.to_s.downcase)
    when OperatorType::NOT_ONE_OF
      !condition.value.map(&:downcase).include?(subject_value.to_s.downcase)
    else
      # Numeric operator: value could be numeric or semver.
      if subject_value.is_a?(Numeric)
        evaluate_numeric_condition(subject_value, condition)
      elsif valid_semver?(subject_value)
        compare_semver(subject_value, condition.value, condition.operator)
      end
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def evaluate_numeric_condition(subject_value, condition)
    case condition.operator
    when OperatorType::GT
      subject_value > condition.value
    when OperatorType::GTE
      subject_value >= condition.value
    when OperatorType::LT
      subject_value < condition.value
    when OperatorType::LTE
      subject_value <= condition.value
    else
      false
    end
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def compare_semver(attribute_value, condition_value, operator)
    unless valid_semver?(attribute_value) && valid_semver?(condition_value)
      return false
    end

    case operator
    when OperatorType::GT
      SemVer.parse(attribute_value) > SemVer.parse(condition_value)
    when OperatorType::GTE
      SemVer.parse(attribute_value) >= SemVer.parse(condition_value)
    when OperatorType::LT
      SemVer.parse(attribute_value) < SemVer.parse(condition_value)
    when OperatorType::LTE
      SemVer.parse(attribute_value) <= SemVer.parse(condition_value)
    else
      false
    end
  end
  # rubocop:enable Metrics/MethodLength

  def valid_semver?(string)
    !SemVer.parse(string).nil?
  end

  module_function :find_matching_rule, :matches_rule, :evaluate_condition,
                  :evaluate_numeric_condition, :valid_semver?, :compare_semver
end
