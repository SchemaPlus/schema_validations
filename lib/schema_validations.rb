# frozen_string_literal: true

require 'valuable'

require 'schema_plus_columns'
require 'schema_validations/version'
require 'schema_validations/validators/not_nil_validator'
require 'schema_validations/active_record/validations'
require 'schema_validations/active_record/type'

module SchemaValidations

  # The configuation options for SchemaValidations. Set them globally in
  # <tt>config/initializers/schema_validations.rb</tt>, e.g.:
  #
  #    SchemaValidations.setup do |config|
  #       config.auto_create = false
  #    end
  #
  # or override them per-model, e.g.:
  #
  #     class MyModel < ActiveRecord::Base
  #        schema_validations :only => [:name, :active]
  #     end
  #
  class Config < Valuable
    ##
    # :attr_accessor: auto_create
    #
    # Whether to automatically create validations based on database constraints.
    # Boolean, default is +true+.
    has_value :auto_create, :klass => :boolean, :default => true

    ##
    # :attr_accessor: only
    #
    # List of field names to include in automatic validation.
    # Value is a single name, and array of names, or +nil+.  Default is +nil+.
    has_value :only, :default => nil

    ##
    # :attr_accessor: whitelist
    #
    # List of field names to exclude from automatic validation.
    # Value is a single name, an array of names, or +nil+.  Default is <tt>[:created_at, :updated_at, :created_on, :updated_on]</tt>.
    has_value :whitelist, :default => [:created_at, :updated_at, :created_on, :updated_on]

    ##
    # :attr_accessor: except
    #
    # List of field names to exclude from automatic validation.
    # Value is a single name, and array of names, or +nil+.  Default is +nil+.
    has_value :except, :default => nil

    ##
    # :attr_accessor: whitelist_type
    #
    # List of validation types to exclude from automatic validation.
    # Value is a single type, and array of types, or +nil+.  Default is +nil+.
    # A type is specified as, e.g., +:validates_presence_of+ or simply +:presence+.
    has_value :whitelist_type, :default => nil

    ##
    # :attr_accessor: except_type
    #
    # List of validation types to exclude from automatic validation.
    # Value is a single type, and array of types, or +nil+.  Default is +nil+.
    # A type is specified as, e.g., +:validates_presence_of+ or simply +:presence+.
    has_value :except_type, :default => nil

    ##
    # :attr_accessor: only_type
    #
    # List of validation types to include in automatic validation.
    # Value is a single type, and array of types, or +nil+.  Default is +nil+.
    # A type is specified as, e.g., +:validates_presence_of+ or simply +:presence+.
    has_value :only_type, :default => nil

    def dup #:nodoc:
      self.class.new(Hash[attributes.collect{ |key, val| [key, Valuable === val ?  val.class.new(val.attributes) : val] }])
    end

    def update_attributes(opts)#:nodoc:
      opts = opts.dup
      opts.keys.each { |key| self.send(key).update_attributes(opts.delete(key)) if self.class.attributes.include? key and Hash === opts[key] }
      super(opts)
      self
    end

    def merge(opts)#:nodoc:
      dup.update_attributes(opts)
    end

  end

  # Returns the global configuration, i.e., the singleton instance of Config
  def self.config
    @config ||= Config.new
  end

  # Initialization block is passed a global Config instance that can be
  # used to configure SchemaValidations behavior.  E.g., if you want to
  # disable automation creation validations put the following in
  # config/initializers/schema_validations.rb :
  #
  #    SchemaValidations.setup do |config|
  #       config.auto_create = false
  #    end
  #
  def self.setup # :yields: config
    yield config
  end

end

SchemaMonkey.register SchemaValidations
