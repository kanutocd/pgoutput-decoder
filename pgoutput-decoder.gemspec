# frozen_string_literal: true

require_relative "lib/pgoutput/decoder/version"

Gem::Specification.new do |spec|
  spec.name = "pgoutput-decoder"
  spec.version = Pgoutput::Decoder::VERSION
  spec.authors = ["Ken C. Demanawa"]
  spec.email = ["kenneth.c.demanawa@gmail.com"]

  spec.summary = "PostgreSQL pgoutput logical replication value decoder."
  spec.description = "Decodes pgoutput-parser protocol messages into immutable Ruby row-change events."
  spec.homepage = "https://github.com/kanutocd/pgoutput-decoder"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "lib/**/*.rb",
    "sig/**/*.rbs",
    "README.md",
    "CHANGELOG.md",
    "LICENSE.txt"
  ]
  spec.require_paths = ["lib"]

  spec.add_dependency "bigdecimal", "~> 4.1"
  spec.add_dependency "pgoutput-parser", "~> 0.1"
end
