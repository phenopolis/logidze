# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

begin
  require "debug" unless ENV["CI"] == "true"
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

require "ammeter"
require "timecop"

require File.expand_path("dummy/config/environment", __dir__)

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.order = :random
  Kernel.srand config.seed

  config.define_derived_metadata(file_path: %r{/spec/sql/}) do |metadata|
    metadata[:type] = :sql
  end

  config.include Logidze::TestHelpers

  config.before(:each, db: true) do
    ActiveRecord::Base.connection.begin_transaction(joinable: false)
  end

  config.append_after(:each, db: true) do |ex|
    ActiveRecord::Base.connection.rollback_transaction

    raise "Migrations are pending: #{ex.metadata[:location]}" if ActiveRecord::Base.connection.migration_context.needs_migration?
  end

  config.around(:each, sequel: true) do |example|
    Sequel::Model.db.transaction(rollback: :always, auto_savepoint: true) { example.run }
  end

  # Sequel does not support table prefixes / suffixes
  if ENV["TABLE_NAME_PREFIX"].present? || ENV["TABLE_NAME_SUFFIX"].present?
    config.filter_run_excluding :sequel
  end
end
