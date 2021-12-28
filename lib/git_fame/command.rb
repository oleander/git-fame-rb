# frozen_string_literal: true

require "active_support/core_ext/enumerable"
require "tty-option"
require "tty-spinner"

module GitFame
  class Command
    include TTY::Option
    using Extension

    usage do
      program "git"
      command "fame"
      desc "GitFame is a tool to generate a contributor list from git history"
      example "Include commits made since 2010", "git fame --after 2010-01-01"
      example "Include commits made before 2015", "git fame --before 2015-01-01"
      example "Include commits made since 2010 and before 2015", "git fame --after 2010-01-01 --before 2015-01-01"
      example "Only changes made to the main branch", "git fame --branch main"
      example "Only ruby and javascript files", "git fame --extensions .rb .js"
      example "Exclude spec files and the README", "git fame --exclude */**/*_spec.rb README.md"
      example "Only spec files and markdown files", "git fame --include */**/*_spec.rb */**/*.md"
      example "A parent directory of the current directory", "git fame ../other/git/repo"
    end

    option :log_level do
      permit ["debug", "info", "warn", "error", "fatal"]
      long "--log-level [LEVEL]"
      desc "Log level"
    end

    option :exclude do
      desc "Exclude files matching the given glob pattern"
      long "--exclude [GLOB]"
      arity zero_or_more
      short "-E [BLOB]"
      convert :list
    end

    option :include do
      desc "Include files matching the given glob pattern"
      long "--include [GLOB]"
      arity zero_or_more
      short "-I [BLOB]"
      convert :list
    end

    option :extensions do
      desc "File extensions to be included starting with a period"
      arity zero_or_more
      long "--extensions [EXT]"
      short "-ex [EXT]"
      convert :list

      validate -> input do
        input.match(/\.\w+/)
      end
    end

    option :before do
      desc "Only changes made after this date"
      long "--before [DATE]"
      short "-B [DATE]"
      validate -> input do
        Types::Params::DateTime.valid?(input)
      end
    end

    option :after do
      desc "Only changes made before this date"
      long "--after [DATE]"
      short "-A [DATE]"

      validate -> input do
        Types::Params::DateTime.valid?(input)
      end
    end

    argument :path do
      desc "Path or sub path to the git repository"
      default { Dir.pwd }
      optional

      validate -> path do
        File.directory?(path)
      end
    end

    option :branch do
      desc "Branch to be used as starting point"
      long "--branch [NAME]"
      default "HEAD"
    end

    flag :help do
      desc "Print usage"
      long "--help"
      short "-h"
    end

    def self.call(argv = ARGV)
      cmd = new
      cmd.parse(argv, raise_on_parse_error: true)
      cmd.run
    rescue TTY::Option::Error => e
      abort e.message
    end

    def run
      if params[:help]
        abort help
      end

      pp ARGV
      spinner = TTY::Spinner.new("[:spinner] git-fame is crunching the numbers, hold on ...", interval: 1)
      spinner.auto_spin
      render = Render.new(result: result, **options(:branch))
      spinner.stop
      render.call
    rescue Dry::Struct::Error => e
      abort e.message
    rescue Interrupt
      exit
    end

    private

    def filter
      Filter.new(**params.to_h.compact_blank.except(:branch))
    end

    def repo
      Rugged::Repository.discover(params[:path])
    end

    def collector
      Collector.new(filter: filter, diff: diff, **options)
    end

    def diff
      Diff.new(commit: commit, **options)
    end

    def options(*args)
      params.to_h.only(*args, :log_level).compact_blank
    end

    def commit
      repo.rev_parse(params[:branch])
    end

    def result
      collector.call
    end
  end
end
