# frozen_string_literal: true

require_relative "lib/git_fame/version"

Gem::Specification.new do |gem|
  gem.name          = "git_fame"
  gem.version       = GitFame::VERSION
  gem.authors       = ["Linus Oleander"]
  gem.email         = ["oleander@users.noreply.github.com"]

  gem.description   = <<~DESC
    A command-line tool that helps you summarize and
    pretty-print collaborators in a git repository
    based on contributions

    Generates stats like:
      - Number of files changed by a user
      - Number of commits by user
      - Lines of code by a user'
  DESC

  gem.summary = <<~SUMMARY
    git-fame is a command-line tool that helps you summarize
    and pretty-print collaborators in a git repository based
    on contributions. A Ruby wrapper for git-blame if you will.
  SUMMARY

  gem.homepage = "https://github.com/oleander/git-fame-rb"
  gem.required_ruby_version = ">= 2.7.0"
  gem.files = Dir["lib/**/*", "exe/*"]
  gem.executables << "git-fame"
  gem.bindir = "exe"

  gem.add_dependency "activesupport", "~> 7.0"
  gem.add_dependency "dry-initializer", "~> 3.0"
  gem.add_dependency "dry-struct", "~> 1.0"
  gem.add_dependency "dry-types", "~> 1.0"
  gem.add_dependency "neatjson", "~> 0.9"
  gem.add_dependency "rugged", "~> 1.0"
  gem.add_dependency "tty-box", "~> 0.5"
  gem.add_dependency "tty-option", "~> 0.2"
  gem.add_dependency "tty-screen", "~> 0.5"
  gem.add_dependency "tty-spinner", "~> 0.9"
  gem.add_dependency "tty-table", "~> 0.9", "<= 0.13.0"
  gem.add_dependency "zeitwerk", "~> 2.0"
  gem.metadata = { "rubygems_mfa_required" => "true" }
end
