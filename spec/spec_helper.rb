require "rspec"
require "git_fame"
require "coveralls"
require "rspec/collection_matchers"
require "rspec/expectations"
require "pp"
require "colorize"
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
  # Set to false to allow Kernel#puts
  suppress_stdout = true

  config.include GitFame::Startup
  config.mock_with :rspec
  config.expect_with(:rspec) do |c|
    c.syntax = [:should, :expect]
  end
  config.mock_with :rspec do |mocks|
    mocks.syntax = :should
  end
  config.fail_fast = false
  config.before(:each) do
    Dir.chdir(repository) { system "git checkout 7ab01bc5a720 > /dev/null 2>&1" }
  end
  config.before(:suite) do
    ENV["TZ"] = "GMT-2"
    warn "-----------"
    warn "Current environment:".yellow
    warn "\t#{`git --version`.strip}"
    warn "\t#{`grep --version`.strip}"
    warn "Spec notes:".yellow
    if suppress_stdout
      warn "\tMessages to STDOUT has been suppressed. See spec/spec_helper.rb".red
    end
    warn "\tRequires git 2.x for specs to pass"
    warn "\tTime zone during testing is set to #{ENV["TZ"]}"
    warn "-----------"
  end
  config.before(:each) do
    $stdout.stub(:puts) if suppress_stdout
  end
end