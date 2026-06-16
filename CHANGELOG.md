# Changelog

## [Unreleased]

## 0.1.1 - 2026-06-17

### Fixed

* Curated RBS signatures shipped with the gem.
* Fixed duplicate `Pgoutput::Decoder` type declarations that caused Steep/RBS environment loading failures.
* Corrected decoder type signatures to align with actual runtime behavior.
* Improved `TypeRegistry` type annotations and value narrowing.
* Fixed Steep type-checking issues around decoder lookup, JSON decoding, UUID decoding, and numeric value decoding.
* Added missing standard library type dependencies required by Steep.
* Improved compatibility with downstream consumers using:

  * `library "pgoutput-decoder"`
  * `bundle exec steep check`

### Documentation

* Refined shipped type definitions to better reflect the public API surface.

### Internal

* No runtime behavior changes.
* No protocol decoding changes.
* No public API changes.
* This release focuses on RBS, Steep, and developer tooling correctness.

## [0.1.0] - 2026-06-01

### Added

- Added initial `pgoutput-decoder` gem structure.
- Added dependency on `pgoutput-parser`.
- Added `Pgoutput::Decoder` facade.
- Added decoded event models for Begin, Commit, Insert, Update, and Delete.
- Added relation cache for parser Relation messages.
- Added active transaction tracking using Begin message XID.
- Added decoded row hash construction from relation columns and tuple values.
- Added default PostgreSQL OID decoders for common scalar types.
- Added conservative binary decoding for fixed-width scalar values.
- Added custom OID decoder support.
- Added Ractor-shareable decoded event outputs.
- Added Minitest coverage for registry, value decoding, row building, relation cache, and integration flows.
- Added RBS signatures.
- Added README documentation.
- Added CI and release workflow templates.
