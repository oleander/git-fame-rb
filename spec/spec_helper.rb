require "rspec"
require "git_fame"
require "coveralls"
require "rspec/collection_matchers"
require_relative "./support/startup"

Coveralls.wear!

RSpec.configure do |config|
  config.include GitFame::Startup
  config.mock_with :rspec
  config.order = "random"
  config.expect_with(:rspec) { |c| c.syntax = [:should, :expect] }
  config.fail_fast = false
  config.before(:all) do
    Dir.chdir(repository) { `git checkout 7ab01bc5a720` }
  end

  # Remove this line to allow Kernel#puts
  config.before { allow($stdout).to receive(:puts) }
end