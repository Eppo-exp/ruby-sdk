# frozen_string_literal: true

# The helper to validate various keys
module EppoClient
  module_function

  def validate_not_blank(field_name, field_value)
    (field_value.nil? || field_value == '') && raise(StandardError, "Invalid value for #{field_name}: cannot be blank")
  end
end
