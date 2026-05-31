# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Placeholder for future development.

---

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

---

[Unreleased]: https://github.com/kanutocd/pgoutput-decoder/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/kanutocd/pgoutput-decoder/releases/tag/v0.1.0
