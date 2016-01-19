module SchemaValidations
  module ActiveRecord
    module Type

      module Integer
        def self.prepended(base)
          base.class_eval do
            public :range
          end
        end
      end
    end
  end
end
