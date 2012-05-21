require "rspec"
require "git_blame"

RSpec.configure do |config|
  config.mock_with :rspec
  config.before { @repository = File.join(File.dirname(File.dirname(__FILE__)), "spec/fixtures/gash") }
end