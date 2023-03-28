# frozen_string_literal: true

require "simplecov"

require "factory_bot"
require "rspec/its"
require "git_fame"
require "faker"
require "rspec"
require "pry"

require_relative "factories"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".stats.rspec"
  config.include FactoryBot::Syntax::Methods
  config.filter_run_when_matching :focus
end
