require "open3"

module GitFame
  module Startup
    def repository
      File.join(File.dirname(File.dirname(__FILE__)), "fixtures/gash")
    end

    def binary
      File.join(File.dirname(File.dirname(__FILE__)), "../bin/git-fame")
    end

    def run(*args)
      Open3.popen2e(*([binary] + args), chdir: repository) do |_, out, thread|
        return [out.read, thread.value.success?]
      end
    rescue Errno::ENOENT
      [$!.message, false]
    end
  end
end