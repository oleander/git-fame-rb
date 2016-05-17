require "rspec"
require "git_fame"
require "coveralls"
require "rspec/collection_matchers"
require_relative "./support/startup"
require "rspec/expectations"

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
  config.expect_with(:rspec) { |c| c.syntax = [:should, :expect] }
  config.fail_fast = false
  config.before(:all) do
    Dir.chdir(repository) { system "git checkout 7ab01bc5a720 > /dev/null 2>&1" }
  end

  # Remove this line to allow Kernel#puts
  config.before { allow($stdout).to receive(:puts) }
end