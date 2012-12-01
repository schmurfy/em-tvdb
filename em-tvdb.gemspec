# -*- encoding: utf-8 -*-
require File.expand_path('../lib/em-tvdb/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Julien Ammous"]
  gem.email         = ["schmurfy@gmail.com"]
  gem.description   = %q{EM tvdb website wrapper}
  gem.summary       = %q{EM tvdb website wrapper}
  gem.homepage      = "https://github.com/schmurfy/em-tvdb"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.name          = "em-tvdb"
  gem.require_paths = ["lib"]
  gem.version       = EmTvdb::VERSION
  
  gem.add_dependency 'rest-core',       '~> 1.0.2'
  gem.add_dependency 'nokogiri',        '~> 1.5.0'
  gem.add_dependency 'em-http-request'
  gem.add_dependency 'hashie'
  gem.add_dependency 'eventmachine',    '~> 1.0.0.rc'
  
end
