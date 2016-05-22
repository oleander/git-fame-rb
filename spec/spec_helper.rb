require "rspec"
require "git_fame"
require "coveralls"
require "rspec/collection_matchers"
require "rspec/expectations"
require "active_support/time"
require "pp"
require_relative "./support/startup"

Coveralls.wear!

RSpec::Matchers.define :be_a_succees do
  match do |actual|
    actual.last
  end

  failure_message do |actual|
    "expected command to be a success, but failed"
  end
end

RSpec::Matchers.define :include_output do |expected|
  match do |actual|
    actual.first.include?(expected)
  end

  failure_message do |actual|
    "expected #{actual} to include #{expected}, but didn't"
  end
end

RSpec.configure do |config|
  config.include GitFame::Startup
  config.mock_with :rspec
  config.order = "random"
  config.expect_with(:rspec) do |c|
    c.syntax = [:should, :expect]
  end
  config.mock_with :rspec do |mocks|
    mocks.syntax = :should
  end
  config.fail_fast = false

  config.before(:each) do
    zone = ActiveSupport::TimeZone.new("Stockholm")
    Time.stub(:now){ Time.new.in_time_zone(zone) }
  end

  config.before(:all) do
    warn "-----------"
    warn "Current environment"
    warn `git --version`
    warn `grep --version`
    warn `head --version`
    warn "-----------"
    Dir.chdir(repository) { system "git checkout 7ab01bc5a720 > /dev/null 2>&1" }
  end

  # Remove this line to allow Kernel#puts
  # config.before { allow($stdout).to receive(:puts) }
end