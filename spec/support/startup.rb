module GitFame
  module Startup
    def repository
      File.join(File.dirname(File.dirname(__FILE__)), "fixtures/gash")
    end
  end
end