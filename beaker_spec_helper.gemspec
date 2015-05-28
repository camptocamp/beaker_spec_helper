# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "beaker_spec_helper/version"

Gem::Specification.new do |s|
  s.name        = "beaker_spec_helper"
  s.version     = BeakerSpecHelper::Version::STRING
  s.authors     = ["Camptocamp"]
  s.email       = ["mickael.canevet@camptocamp.com"]
  s.homepage    = "http://github.com/camptocamp/beaker_spec_helper"
  s.summary     = "Standard configuration for beaker spec tests"
  s.description = "Contains a standard spec_helper for running acceptance tests on puppet modules"
  s.licenses    = 'Apache-2.0'

  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  s.add_runtime_dependency 'beaker', '~> 2'
end
