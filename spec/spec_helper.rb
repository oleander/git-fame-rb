require "rspec"
require "git_fame"
require "coveralls"

Coveralls.wear!

RSpec.configure do |config|
  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  config.order = "random"
  config.before(:all) do
    @repository = File.join(File.dirname(File.dirname(__FILE__)), "spec/fixtures/gash")
    Dir.chdir(@repository) do
      `git checkout 7ab01bc5a720`
    end
  end
end
