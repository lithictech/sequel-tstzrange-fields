# frozen_string_literal: true

require_relative "lib/sequel/plugins/tstzrange_fields"

Gem::Specification.new do |spec|
  spec.name          = "sequel-plugins-tstzrange-fields"
  spec.version       = Sequel::Plugins::TstzrangeFields::VERSION
  spec.authors       = ["Natalie"]
  spec.email         = ["natalie@lithic.tech"]

  spec.summary       = "Gem for enabling time ranges when working with postgres"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.add_dependency("activesupport")
  spec.add_dependency("pg")
  spec.add_dependency("sequel")
  spec.add_dependency("yajl-ruby")
  spec.add_development_dependency("rspec")
end