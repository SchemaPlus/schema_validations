# frozen_string_literal: true

SimpleCov.configure do
  enable_coverage :branch
  add_filter '/spec/'

  add_group 'Binaries', '/bin/'
  add_group 'Libraries', '/lib/'

  if ENV['CI']
    require 'simplecov-lcov'

    SimpleCov::Formatter::LcovFormatter.config do |c|
      c.report_with_single_file = true
      c.single_report_path = 'coverage/lcov.info'
    end

    formatter SimpleCov::Formatter::LcovFormatter
  end
end
