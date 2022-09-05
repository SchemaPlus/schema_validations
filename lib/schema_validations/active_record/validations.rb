# frozen_string_literal: true

module SchemaValidations
  module ActiveRecord
    module Base

      def load_schema_validations
        self.class.send :load_schema_validations
      end

      module ClassMethods

        def self.extended(base)
          base.class_eval do
            class_attribute :schema_validations_loaded
          end
        end

        def inherited(subclass) # :nodoc:
          super
          before_validation :load_schema_validations unless schema_validations_loaded?
        end

        def validators
          load_schema_validations unless schema_validations_loaded?
          super
        end

        def validators_on(*args)
          load_schema_validations unless schema_validations_loaded?
          super
        end

        # Per-model override of Config options.  Use via, e.g.
        #     class MyModel < ActiveRecord::Base
        #         schema_validations :auto_create => false
        #     end
        #
        # If <tt>:auto_create</tt> is not specified, it is implicitly
        # specified as true.  This allows the "non-invasive" style of using
        # SchemaValidations in which you set the global Config to
        # <tt>auto_create = false</tt>, then in any model that you want auto
        # validations you simply do:
        #
        #     class MyModel < ActiveRecord::Base
        #         schema_validations
        #     end
        #
        #  Of course other options can be passed, such as
        #
        #     class MyModel < ActiveRecord::Base
        #         schema_validations :except_type => :validates_presence_of
        #     end
        #
        #
        def schema_validations(opts={})
          @schema_validations_config = SchemaValidations.config.merge({:auto_create => true}.merge(opts))
        end

        def schema_validations_config # :nodoc:
          @schema_validations_config ||= SchemaValidations.config.dup
        end

        private
        # Adds schema-based validations to model.
        # Attributes as well as associations are validated.
        # For instance if there is column
        #
        #     <code>email NOT NULL</code>
        #
        # defined at database-level it will be translated to
        #
        #     <code>validates_presence_of :email</code>
        #
        # If there is an association named <tt>user</tt>
        # based on <tt>user_id NOT NULL</tt> it will be translated to
        #
        #     <code>validates_presence_of :user</code>
        #
        #  Note it uses the name of association (user) not the column name (user_id).
        #  Only <tt>belongs_to</tt> associations are validated.
        #
        #  This accepts following options:
        #  * :only - auto-validate only given attributes
        #  * :except - auto-validate all but given attributes
        #
        def load_schema_validations #:nodoc:
          # Don't bother if: it's already been loaded; the class is abstract; not a base class; or the table doesn't exist
          return unless create_schema_validations?
          load_column_validations
          load_association_validations
          self.schema_validations_loaded = true
        end

        def load_column_validations #:nodoc:
          content_columns.each do |column|
            name = column.name.to_sym

            # Data-type validation
            datatype = case
                       when respond_to?(:defined_enums) && defined_enums.has_key?(column.name) then :enum
                       when column.type == :integer then :integer
                       when column.type == :decimal || column.type == :money then :decimal
                       when column.type == :float   then :numeric
                       when column.type == :text || column.type == :string then :text
                       when column.type == :boolean then :boolean
                       end

            case datatype
            when :integer
              load_integer_column_validations(name, column)
            when :decimal
              if column.precision
                limit = 10 ** (column.precision - (column.scale || 0))
                validate_logged :validates_numericality_of, name, :allow_nil => true, :greater_than => -limit, :less_than => limit
              end
            when :numeric
              validate_logged :validates_numericality_of, name, :allow_nil => true
            when :text
              validate_logged :validates_length_of, name, :allow_nil => true, :maximum => column.limit if column.limit
            end

            # NOT NULL constraints
            if column.required_on
              if datatype == :boolean
                validate_logged :validates_inclusion_of, name, :in => [true, false], :message => :blank
              else
                if !column.default.nil? && column.default.blank?
                  validate_logged :validates_with, SchemaValidations::Validators::NotNilValidator, attributes: [name]
                else
                  # Validate presence
                  validate_logged :validates_presence_of, name
                end
              end
            end

            # UNIQUE constraints
            add_uniqueness_validation(column) if column.unique?
          end
        end

        def load_integer_column_validations(name, column) # :nodoc:
          integer_range = ::ActiveRecord::Type::Integer.new.range
          # The Ruby Range object does not support excluding the beginning of a Range,
          # so we always include :greater_than_or_equal_to
          options = { :allow_nil => true, :only_integer => true, greater_than_or_equal_to: integer_range.begin }

          if integer_range.exclude_end?
            options[:less_than] = integer_range.end
          else
            options[:less_than_or_equal_to] = integer_range.end
          end

          validate_logged :validates_numericality_of, name, options
        end

        def load_association_validations #:nodoc:
          reflect_on_all_associations(:belongs_to).each do |association|
            # :primary_key_name was deprecated (noisily) in rails 3.1
            foreign_key_method = (association.respond_to? :foreign_key) ?  :foreign_key : :primary_key_name
            column = columns_hash[association.send(foreign_key_method).to_s]
            next unless column

            # NOT NULL constraints
            validate_logged :validates_presence_of, association.name if column.required_on

            # UNIQUE constraints
            add_uniqueness_validation(column) if column.unique?
          end
        end

        def add_uniqueness_validation(column) #:nodoc:
          scope = column.unique_scope.map(&:to_sym)
          name = column.name.to_sym

          options = {}
          options[:scope] = scope if scope.any?
          options[:allow_nil] = true
          options[:case_sensitive] = false if has_case_insensitive_index?(column, scope)
          options[:if] = (proc do |record|
            if scope.all? { |scope_sym| record.public_send(:"#{scope_sym}?") }
              record.public_send(:"#{column.name}_changed?")
            else
              false
            end
          end)

          validate_logged :validates_uniqueness_of, name, options
        end

        def has_case_insensitive_index?(column, scope)
          indexed_columns = (scope + [column.name]).map(&:to_sym).sort
          index = column.indexes.select { |i| i.unique && i.columns.map(&:to_sym).sort == indexed_columns }.first

          index && index.respond_to?(:case_sensitive?) && !index.case_sensitive?
        end

        def create_schema_validations? #:nodoc:
          schema_validations_config.auto_create? && !(schema_validations_loaded || abstract_class? || name.blank? || !table_exists?)
        end

        def validate_logged(method, arg, opts={}) #:nodoc:
          if _filter_validation(method, arg, opts)
            msg = "[schema_validations] #{self.name}.#{method} #{arg.inspect}"
            msg += ", #{opts.inspect[1...-1]}" if opts.any?
            logger.debug msg if logger
            send method, arg, opts
          end
        end

        def _filter_validation(macro, name, opts) #:nodoc:
          config = schema_validations_config
          types = [macro]

          case macro.to_s
            when /^validates_(.*)_of$/
              types << Regexp.last_match[1].to_sym
            when 'validates_with'
              types << name
              name = opts[:attributes].first
          end

          return false if config.only           and not Array.wrap(config.only).include?(name)
          return false if config.except         and     Array.wrap(config.except).include?(name)
          return false if config.whitelist      and     Array.wrap(config.whitelist).include?(name)
          return false if config.only_type      and not (Array.wrap(config.only_type) & types).any?
          return false if config.except_type    and     (Array.wrap(config.except_type) & types).any?
          return false if config.whitelist_type and     (Array.wrap(config.whitelist_type) & types).any?
          return true
        end

      end
    end

  end
end
