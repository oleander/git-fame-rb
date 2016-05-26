#!/usr/bin/env rake

require "bundler/gem_tasks"
require "method_profiler"
require "git_fame"

task :profile do
  profiler = MethodProfiler.observe(GitFame::Base)

  GitFame::Base.new({
    repository: "spec/fixtures/gash"
  })

  puts profiler.report
end
