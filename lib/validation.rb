# frozen_string_literal: true

require 'custom_errors'

# The helper module to validate keys
module EppoClient
  def validate_not_blank(field_name, field_value)
    (field_value.nil? || field_value == '') && raise(EppoClient::InvalidValueError, "#{field_name} cannot be blank")
  end

  module_function :validate_not_blank
end
