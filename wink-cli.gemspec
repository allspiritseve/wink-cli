lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wink/cli/version'

Gem::Specification.new do |spec|
  spec.name = 'wink-cli'
  spec.version = Wink::Cli::VERSION
  spec.authors = ["Cory Kaufman-Schofield"]
  spec.email = ["cory@corykaufman.com"]
  spec.summary = "Wink command-line application"
  spec.homepage = "https://github.com/allspiritseve/wink-cli"
  spec.license = "MIT"
  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^test/})
  end
  spec.bindir = 'bin'
  spec.executables = ['wink']
  spec.require_paths = ["lib"]
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'minitest'
end
