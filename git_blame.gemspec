# -*- encoding: utf-8 -*-
require File.expand_path('../lib/git_blame/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Linus Oleander"]
  gem.email         = ["linus@oleander.nu"]
  gem.description   = %q{Ruby Git blame}
  gem.summary       = %q{Ruby Git blame}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "git_blame"
  gem.require_paths = ["lib"]
  gem.version       = GitBlame::VERSION
  gem.executables = ["blame"]
end
