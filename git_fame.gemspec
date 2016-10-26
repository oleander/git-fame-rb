# -*- encoding: utf-8 -*-
require File.expand_path('../lib/git_fame/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Linus Oleander"]
  gem.email         = ["linus@oleander.nu"]
  gem.description   = "A command-line tool that helps you summarize and pretty-print collaborators in a git repository based on contributions"
  gem.summary       = %q{
git-fame is a command-line tool that helps you summarize and pretty-print collaborators in a git repository based on contributions. A Ruby wrapper for git-blame if you will.

Generates stats like:
- Number of files changed by a user
- Number of commits by user
- Lines of code by a user}

  gem.homepage      = "http://oleander.io/git-fame-rb"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "git_fame"
  gem.require_paths = ["lib"]
  gem.version       = GitFame::VERSION

  gem.add_dependency("progressbar", "~> 0.21.0")
  gem.add_dependency("trollop", "~> 2.1.2")
  gem.add_dependency("hirb", "~> 0.7.3")
  gem.add_dependency("scrub_rb", "~> 1.0.1")
  gem.add_dependency("memoist", "~> 0.14.0")
  gem.add_dependency("method_profiler", "~> 2.0.1")

  gem.add_development_dependency("rspec", "~> 3.4.0")
  gem.add_development_dependency("rspec-collection_matchers", "~> 1.1.2")
  gem.add_development_dependency("rake", "~> 10.4.2")
  gem.add_development_dependency("coveralls", "~> 0.8.1")
  gem.add_development_dependency("json", "~> 1.8.3")
  gem.add_development_dependency("tins", "~> 1.6.0")
  gem.add_development_dependency("term-ansicolor", "~> 1.3.2")

  gem.required_ruby_version = ">= 1.9.2"
end
