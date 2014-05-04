# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_list/version'

Gem::Specification.new do |spec|
  spec.name          = "active_list"
  spec.version       = ActiveList::VERSION
  spec.author        = "Brice Texier"
  spec.email         = "burisu@oneiros.fr"
  spec.summary       = "Simple interactive tables for Rails app"
  spec.description   = "Generates action methods to provide clean tables."
  spec.homepage      = "http://github.com/burisu/active_list"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z app lib locales LICENSE.txt README.rdoc test`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", [">= 3.2", "< 4.1"]
  # spec.add_dependency "compass-rails", ["~> 1.1.7"]
  spec.add_dependency "code_string", [">= 0.0.0"]
  spec.add_dependency "rubyzip", [">= 1.0"]
  spec.add_dependency "fastercsv", [">= 1.5"]
  spec.add_dependency "i18n-complements", [">= 0"]
  spec.add_development_dependency("sqlite3", [">= 0"])
end

