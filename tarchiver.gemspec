# coding: utf-8
lib = ::File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tarchiver/version'

Gem::Specification.new do |spec|
  spec.name          = "tarchiver"
  spec.version       = Tarchiver::VERSION
  spec.authors       = ["Bart Kamphorst"]
  spec.email         = ["bart@kamphorst.com"]
  spec.summary       = %q{A high-level tar and tgz archiver.}
  spec.description   = %q{A high-level tar and tgz archiver.}
  spec.homepage      = "https://github.com/bartkamphorst/tarchiver"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| ::File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec"
  
end
