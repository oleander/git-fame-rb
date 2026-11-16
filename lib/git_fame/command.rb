# frozen_string_literal: true

require "active_support/core_ext/enumerable"
require "active_support/core_ext/object/blank"
require "tty-option"
require "tty-screen"
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
      example "Lines as of a tag or commit", "git fame --branch v1.0.0"
      example "Only ruby and javascript files", "git fame --extensions .rb .js"
      example "Exclude spec files and the README", "git fame --exclude '*/**/*_spec.rb' README.md"
      example "Only spec files and markdown files", "git fame --include '*/**/*_spec.rb' '*/**/*.md'"
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
      short "-E [GLOB]"
      convert :list
    end

    option :include do
      desc "Include files matching the given glob pattern"
      long "--include [GLOB]"
      arity zero_or_more
      short "-I [GLOB]"
      convert :list
    end

    option :extensions do
      desc "File extensions to be included starting with a period"
      arity zero_or_more
      long "--extensions [EXT]"
      short "-e [EXT]"
      convert :list

      validate -> input do
        input.match(/\.\w+/)
      end
    end

    option :before do
      desc "Only changes made before this date"
      long "--before [DATE]"
      short "-B [DATE]"
      validate -> input do
        Types::Params::DateTime.valid?(input)
      end
    end

    option :after do
      desc "Only changes made after this date"
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
      desc "Branch, tag or commit to be used as starting point"
      long "--branch [NAME]"
      default "HEAD"
    end

    flag :version do
      desc "Current version"
      long "--version"
      short "-v"
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
    rescue TTY::Option::InvalidParameter, TTY::Option::InvalidArgument => e
      abort e.message
    end

    def run
      if params[:help]
        puts help
        exit
      end

      if params[:version]
        puts "git-fame v#{GitFame::VERSION}"
        exit
      end

      render = spin do
        Render.new(result:, width: terminal_width, **options(:branch))
      end

      render.call
    rescue Dry::Struct::Error => e
      abort e.message
    rescue Rugged::Error, Rugged::InvalidError => e
      abort "Error: #{e.message}"
    rescue Interrupt
      exit 130
    end

    private

    def filter
      @filter ||= Filter.new(**params.to_h.compact_blank.except(:branch))
    end

    # Runs the block in this thread while the spinner animates in another
    def spin
      spinner.auto_spin
      yield
    ensure
      spinner.stop
    end

    def spinner
      @spinner ||= TTY::Spinner.new("[:spinner] git-fame is crunching the numbers, hold on ...", interval: 1)
    end

    # Output that is piped or redirected is not limited to a screen width
    def terminal_width
      TTY::Screen.width if $stdout.tty?
    end

    def repo
      @repo ||= Rugged::Repository.discover(params[:path])
    end

    def collector
      Collector.new(filter:, diff:, **options)
    end

    def diff
      Diff.new(commit:, path_filter: filter, **options)
    end

    def options(*)
      params.to_h.only(*, :log_level).compact_blank
    end

    # @raise [Rugged::Error] if the repository has no commits or the
    #   revision is not a branch, tag or commit
    def commit
      if repo.empty?
        raise Rugged::ReferenceError, "repository at '#{repo.workdir || repo.path}' has no commits"
      end

      # Peels annotated tags to the commit they point to
      repo.rev_parse("#{params[:branch]}^{commit}")
    rescue Rugged::InvalidError, Rugged::ReferenceError, Rugged::ObjectError
      raise if repo.empty?

      raise Rugged::ReferenceError, "unknown revision '#{params[:branch]}'"
    end

    def result
      collector.call
    end
  end
end
