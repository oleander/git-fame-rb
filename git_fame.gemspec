# -*- encoding: utf-8 -*-
require File.expand_path('../lib/git_fame/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Linus Oleander"]
  gem.email         = ["linus@oleander.nu"]
  gem.description   = %q{Generates some awesome stats from git-blame}
  gem.summary       = %q{
Generates some awesome stats from git-blame

A Ruby wrapper for git-blame.
Generates data like:
- Number of files changed by a user
- Number of commits by user
- Lines of code by a user
  }
  
  gem.homepage      = "https://github.com/oleander/git-fame-rb"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "git_fame"
  gem.require_paths = ["lib"]
  gem.version       = GitFame::VERSION

  gem.add_dependency("progressbar")
  gem.add_dependency("trollop")
  gem.add_dependency("hirb")
  gem.add_dependency("mimer_plus")
  
  gem.add_development_dependency("rspec")
  gem.required_ruby_version = ">= 1.9.2"
end