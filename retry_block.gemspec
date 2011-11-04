# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "retry_block/version"

Gem::Specification.new do |s|
  s.name        = "retry_block"
  s.version     = RetryBlock::VERSION
  s.authors     = ["Alfred J. Fazio"]
  s.email       = ["alfred.fazio@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Take control of unstable or indeterminate code with retry_block}
  s.description = %q{Take control of unstable or indeterminate code with retry_block}

  s.rubyforge_project = "retry_block"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
