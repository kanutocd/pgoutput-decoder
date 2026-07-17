# pgoutput-decoder

A PostgreSQL logical replication value decoder for Ruby.

`pgoutput-decoder` converts raw PostgreSQL logical replication values into native Ruby objects using PostgreSQL type OIDs.

It sits between protocol parsing and event processing.

```text
PostgreSQL WAL
       |
       v
pgoutput-parser
       |
       v
pgoutput-decoder
       |
       v
Ruby values
       |
       v
cdc-core
```

The gem is intentionally focused on value decoding.

It does not:

* Open replication connections
* Parse pgoutput protocol messages
* Manage replication slots
* Build CDC pipelines
* Process events

Its sole responsibility is converting PostgreSQL values into Ruby objects.

---

# Architecture

```text
Raw tuple value
       |
       v
pgoutput-decoder
       |
       v
Ruby object
```

Example:

```text
"7"
    ↓
Integer

"true"
    ↓
TrueClass

"2026-05-31"
    ↓
Date

"{a,b,c}"
    ↓
Array
```

---

# Quick Start

```ruby
require "pgoutput/decoder"

decoder = Pgoutput::Decoder.new

decoder.decode(
  oid: 23,
  value: "42"
)
# => 42
```

---

# Core Concepts

## Decoder

The primary entry point.

```ruby
decoder = Pgoutput::Decoder.new

decoder.decode(
  oid: 23,
  value: "42"
)
```

Returns the corresponding Ruby value.

---

## Type OIDs

PostgreSQL identifies types using Object Identifiers (OIDs).

Examples:

| OID  | PostgreSQL Type |
| ---- | --------------- |
| 16   | boolean         |
| 20   | bigint          |
| 21   | smallint        |
| 23   | integer         |
| 25   | text            |
| 114  | json            |
| 3802 | jsonb           |

The decoder uses OIDs to determine which conversion strategy to apply.

---

# Supported Types

Current support includes:

* Boolean
* Smallint
* Integer
* Bigint
* Numeric
* Real
* Double Precision
* Text
* Varchar
* JSON
* JSONB
* UUID
* Date
* Timestamp
* Timestamptz
* Arrays

Refer to the API documentation for the complete list.

---

# Decoding Examples

## Integer

```ruby
decoder.decode(
  oid: 23,
  value: "42"
)
# => 42
```

---

## Boolean

```ruby
decoder.decode(
  oid: 16,
  value: "t"
)
# => true
```

---

## JSONB

```ruby
decoder.decode(
  oid: 3802,
  value: '{"name":"Alice"}'
)
# => { "name" => "Alice" }
```

---

## UUID

```ruby
decoder.decode(
  oid: 2950,
  value: "550e8400-e29b-41d4-a716-446655440000"
)
```

---

## Array

```ruby
decoder.decode(
  oid: 1009,
  value: "{red,green,blue}"
)
# => ["red", "green", "blue"]
```

---

# Integration Example

Update and delete `old_key` hashes contain only the columns flagged as
replica-key columns by relation metadata. Composite and non-`id` keys are
preserved without non-key placeholders.

Using `pgoutput-parser` and `pgoutput-decoder` together:

```text
pgoutput-parser
        ↓
TupleValue
        ↓
pgoutput-decoder
        ↓
Ruby object
```

Example:

```ruby
tuple_value = insert.tuple.first

decoder.decode(
  oid: tuple_value.oid,
  value: tuple_value.raw
)
```

---

# Ractor Safety

Decoder instances are safe to use in parallel execution models.

The gem is designed to integrate cleanly with:

```text
Ractors
Fibers
Thread pools
CDC runtimes
```

without requiring framework-specific behavior.

---

# Non-Goals

`pgoutput-decoder` intentionally does not:

* Parse pgoutput protocol messages
* Open PostgreSQL connections
* Manage logical replication
* Build CDC pipelines
* Persist events
* Integrate with ActiveRecord

Those concerns belong elsewhere in the ecosystem.

---

# Ecosystem Position

```text
PostgreSQL
      |
      v
pgoutput-parser
      |
      v
pgoutput-decoder
      |
      v
cdc-core
```

Responsibilities:

```text
pgoutput-parser
    Parse protocol messages

pgoutput-decoder
    Decode PostgreSQL values

cdc-core
    Process events
```

Each layer provides standalone value.

---

# Public API

See the generated API documentation for:

* Decoder
* TypeRegistry
* Built-in Decoders
* OID Mappings

---

# Development

Generate documentation:

```bash
bundle exec yard doc
```

Run tests:

```bash
bundle exec rake test
```

Run coverage:

```bash
bundle exec rake test
```

The test task writes the line and branch report to `coverage/` and enforces the
configured minimums.

Run Steep:

```bash
bundle exec steep check
```

---

# License

MIT
