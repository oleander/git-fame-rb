# frozen_string_literal: true

require "active_support/core_ext/enumerable"
require "tty-option"
require "tty-spinner"

module GitFame
  class Command
    include TTY::Option
    using Extension

    option :log_level do
      long "--log-level [LEVEL]"
    end

    option :exclude do
      arity zero_or_more
      long "--exclude [GLOB]"
      short "-E [BLOB]"
      convert :list
    end

    option :include do
      arity zero_or_more
      long "--include [GLOB]"
      short "-I [BLOB]"
      convert :list
    end

    option :extensions do
      arity zero_or_more
      long "--extensions [EXT]"
      short "-ex [EXT]"
      convert :list

      validate -> input do
        input.match(/\.\w+/)
      end
    end

    option :before do
      long "--before [DATE]"
      short "-B [DATE]"
      validate -> input do
        Types::Params::DateTime.valid?(input)
      end
    end

    option :after do
      long "--after [DATE]"
      short "-A [DATE]"

      validate -> input do
        Types::Params::DateTime.valid?(input)
      end
    end

    option :path do
      long "--path [PATH]"
      short "-P [PATH]"
      default { Dir.pwd }
    end

    option :branch do
      long "--branch [NAME]"
      default "HEAD"
    end

    flag :help do
      short "-h"
      long "--help"
      desc "Print usage"
    end

    def self.call
      cmd = new
      cmd.parse(raise_on_parse_error: true)
      cmd.run
    rescue TTY::Option::InvalidArgument => e
      abort e.message
    end

    def run
      if params[:help]
        abort help
      end

      spinner = TTY::Spinner.new("[:spinner] git-fame is crunching the numbers, hold on ...", interval: 1)
      spinner.auto_spin
      render = Render.new(result: result, **options(:branch))
      spinner.stop
      render.call
    rescue Dry::Struct::Error => e
      abort e.message
    rescue Interrupt
      abort "Interrupted ..."
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
