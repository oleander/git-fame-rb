require "rspec"
require "git_fame"

RSpec.configure do |config|
  config.mock_with :rspec
  config.order = "random"
  config.before(:all) do 
    @repository = File.join(File.dirname(File.dirname(__FILE__)), "spec/fixtures/gash")
    Dir.chdir(@repository) do
      `git checkout d0dbdc7 2&> /dev/null`
    end
  end
end