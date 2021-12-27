# frozen_string_literal: true

require "bundler/setup"

Bundler.require

require "active_support/core_ext/numeric/time"
require "rspec/its"
require "pathname"
require "git_fame"
require "rspec"
require "json"
require "pry"

require_relative "support/dumpable"

class GitFame::Base
  include Dumpable
end

class GitFame::Collector
  include Dumpable
end

module Support
  def fixture_path(path)
    Pathname(__dir__).join("fixtures").join(path)
  end

  def fixture(path)
    JSON.parse(fixture_path(path).read, symbolize_names: true)
  end
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".stats.rspec"
  config.filter_run_when_matching :focus
  config.include Support
end
