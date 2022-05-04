# frozen_string_literal: true

module SchemaValidations
  class Railtie < Rails::Railtie #:nodoc:

    initializer 'schema_validations.insert', :after => "schema_plus.insert" do
      ActiveSupport.on_load(:active_record) do
        SchemaValidations.insert
      end
    end

  end
end
