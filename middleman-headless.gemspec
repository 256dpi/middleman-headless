$LOAD_PATH.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'middleman-headless'
  s.version     = '0.4.1'
  s.licenses    = ['MIT']
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Joël Gähwiler']
  s.email       = ['joel@twomanyprojects.com']
  s.homepage    = 'https://github.com/twomanyprojects/middleman-headless'
  s.summary     = 'Middleman extension to load content from the Headless CMS.'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_runtime_dependency('middleman-core', ['~> 4.1'])
  s.add_runtime_dependency('mime-types', ['~> 3.1'])
  s.add_runtime_dependency('nokogiri', ['~> 1.10'])
  s.add_runtime_dependency('oauth2', ['~> 1.4'])
end
