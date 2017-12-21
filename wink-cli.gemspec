# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require './lib/wink/cli'

Gem::Specification.new do |spec|
  spec.name = 'wink-cli'
  spec.version = Wink::CLI::VERSION
  spec.authors = ['Cory Kaufman-Schofield']
  spec.email = ['cory@corykaufman.com']

  spec.summary = 'Wink command-line application'
  spec.homepage = 'https://github.com/allspiritseve/wink-cli'
  spec.license = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^test/}) }
  spec.bindir = 'bin'
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday'
  spec.add_dependency 'faraday_middleware'
  spec.add_dependency 'json'
  spec.add_dependency 'launchy'
  spec.add_dependency 'rack'
  spec.add_dependency 'rake'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'minitest-reporters'
end
