# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redis/autosuggest/version'

Gem::Specification.new do |gem|
  gem.name          = "redis-autosuggest"
  gem.version       = Redis::Autosuggest::VERSION
  gem.authors       = ["Adam Phan"]
  gem.email         = ["aphansh@gmail.com"]
  gem.description   = %q{Provides autocompletions through Redis, with the ability to rank
  results and integrate with Rails}
  gem.summary       = %q{Suggestions/autocompletions with Redis and Ruby}
  gem.homepage      = "https://github.com/aphan/redis-autosuggest"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency("redis", "~> 3.0.2")
  gem.add_dependency("redis-namespace", "~> 1.2.1")
  gem.add_dependency("levenshtein-ffi", "~> 1.0.3")
  gem.add_dependency("text", "~> 1.2.1")

  gem.add_development_dependency("minitest", "~> 4.3.3")
end
