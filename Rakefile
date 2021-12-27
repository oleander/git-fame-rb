#!/usr/bin/env rake
# frozen_string_literal: true

require "bundler/gem_tasks"
require "method_profiler"
require "git_fame"

desc "Benchmark GitFame"
task :profile do
  profiler = MethodProfiler.observe(GitFame::Base)

  GitFame::Base.new({ repository: "spec/fixtures/gash" })

  puts profiler.report
end
