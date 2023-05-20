# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "tap_parser/version"

Gem::Specification.new do |spec|
  spec.name          = "tap_parser"
  spec.version       = TapParser::VERSION
  spec.licenses      = ['Apache-2.0']
  spec.authors       = ["Ian Katz"]
  spec.email         = ["ianfixes@gmail.com"]

  spec.summary       = "Parser for the Test Anything Protocol (TAP)"
  spec.description   = spec.description
  spec.homepage      = "http://github.com/ianfixes/tap_parser"

  rejection_regex    = %r{^(test|spec|features)/}
  libfiles           = Dir['lib/**/*.*'].reject { |f| f.match(rejection_regex) }
  spec.files         = ['README.md', 'REFERENCE.md', '.yardopts'] + libfiles

  spec.require_paths = ["lib"]
end
