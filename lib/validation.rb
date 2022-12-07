# frozen_string_literal: true

# The HTTP Client
module EppoClient
  module_function

  def validate_not_blank(field_name, field_value)
    (field_value.nil? || field_value == '') && raise(StandardError, "Invalid value for #{field_name}: cannot be blank")
  end
end
