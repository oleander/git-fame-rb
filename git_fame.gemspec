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

  gem.homepage              = "https://github.com/oleander/git-fame-rb"
  gem.files                  = Dir["lib/**/*"]
  gem.required_ruby_version = ">= 2.7.0"
  gem.executables           << "git-fame"
  gem.bindir                = "exe"

  gem.add_dependency "activesupport", "~> 7.0"
  gem.add_dependency "dry-core"
  gem.add_dependency "dry-initializer"
  gem.add_dependency "dry-struct"
  gem.add_dependency "dry-types"
  gem.add_dependency "neatjson"
  gem.add_dependency "rugged", "~> 1.0"
  gem.add_dependency "tty-box"
  gem.add_dependency "tty-option"
  gem.add_dependency "tty-screen"
  gem.add_dependency "tty-spinner"
  gem.add_dependency "tty-table", "0.10.0"
  gem.add_dependency "zeitwerk"
end
