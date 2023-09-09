# frozen_string_literal: true
require 'json'

module EppoClient
  # The class for configuring the Eppo client singleton
  module VariationType
    STRING = 'string'
    NUMERIC = 'numeric'
    BOOLEAN = 'boolean'
    JSON = 'json'

    def is_expected_type(assigned_variation, expected_variation_type)
        case expected_variation_type
        when VariationType.STRING
            assigned_variation.typedValue.is_a?(String)
        when VariationType.NUMERIC
            assigned_variation.typedValue.is_a?(Numeric)
        when VariationType.BOOLEAN
            assigned_variation.typedValue.is_a?(TrueClass) || assigned_variation.typedValue.is_a?(FalseClass)
        when VariationType.JSON
            begin
              parsed_json = JSON.parse(assigned_variation.value)
              JSON.dump(assigned_variation.typedValue)
              parsed_json == assigned_variation.typedValue
            rescue JSON::JSONError
              false
            end
        else
            false
        end
    end
end
