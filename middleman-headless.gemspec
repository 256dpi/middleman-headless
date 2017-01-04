# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'middleman-headless'
  s.version     = '0.3.0'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Joël Gähwiler']
  s.email       = ['joel@twomanyprojects.com']
  # s.homepage    = 'http://example.com'
  s.summary     = %q{Middleman extension to load content from the Headless Content Management System.}
  # s.description = %q{A longer description of your extension}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
  
  # The version of middleman-core your extension depends on
  s.add_runtime_dependency('middleman-core', ['>= 4.1.6'])
  
  # Additional dependencies
  s.add_runtime_dependency('oauth2', ['>= 1.2.0'])
end
