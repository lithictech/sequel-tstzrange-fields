# frozen_string_literal: true

require_relative "lib/sequel_tstzrange_fields/version"

Gem::Specification.new do |spec|
  spec.name          = "sequel-tstzrange-fields"
  spec.version       = SequelTstzrangeFields::VERSION
  spec.authors       = ["Lithic Tech"]
  spec.email         = ["hello@lithic.tech"]
  spec.summary       = "Gem for enabling time ranges when working with postgres"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")
  spec.add_dependency "pg"
  spec.add_dependency "sequel"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency("rubocop", "~> 1.48")
  spec.add_development_dependency "rubocop-sequel"
  spec.metadata["rubygems_mfa_required"] = "true"
end
