# frozen_string_literal: true

require 'json'

module EppoClient
  # The class for configuring the Eppo client singleton
  module VariationType
    STRING_TYPE = 'string'
    NUMERIC_TYPE = 'numeric'
    BOOLEAN_TYPE = 'boolean'
    JSON_TYPE = 'json'

    # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
    def expected_type?(assigned_variation, expected_variation_type)
      case expected_variation_type
      when STRING_TYPE
        assigned_variation.typed_value.is_a?(String)
      when NUMERIC_TYPE
        assigned_variation.typed_value.is_a?(Numeric)
      when BOOLEAN_TYPE
        assigned_variation.typed_value.is_a?(TrueClass) || assigned_variation.typed_value.is_a?(FalseClass)
      when JSON_TYPE
        begin
          parsed_json = JSON.parse(assigned_variation.value)
          JSON.dump(assigned_variation.typed_value)
          parsed_json == assigned_variation.typed_value
        rescue JSON::JSONError
          false
        end
      else
        false
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity

    module_function :expected_type?
  end
end
