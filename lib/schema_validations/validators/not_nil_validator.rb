# frozen_string_literal: true

module SchemaValidations
  module Validators
    # Validates that the field is not nil?
    # (Unlike the standard PresenceValidator which uses #blank?)
    class NotNilValidator < ActiveModel::EachValidator
      if Gem::Version.new(::ActiveRecord::VERSION::STRING) < Gem::Version.new('6.1')
        def validate_each(record, attr_name, value)
          record.errors.add(attr_name, :blank, options) if value.nil?
        end
      else
        def validate_each(record, attr_name, value)
          record.errors.add(attr_name, :blank, **options) if value.nil?
        end
      end
    end
  end
end
