# pgoutput-decoder

[![Gem Version](https://badge.fury.io/rb/pgoutput-decoder.svg)](https://badge.fury.io/rb/pgoutput-decoder)
[![CI](https://github.com/kanutocd/pgoutput-decoder/workflows/CI/badge.svg)](https://github.com/kanutocd/pgoutput-decoder/actions)
[![Ruby Version](https://img.shields.io/badge/ruby-%3E%3D%203.4-ruby.svg)](https://www.ruby-lang.org/en/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A high-level PostgreSQL `pgoutput` logical replication value decoder for Ruby.

`pgoutput-decoder` is the companion layer to [`pgoutput-parser`](https://rubygems.org/gems/pgoutput-parser). It accepts immutable protocol messages produced by `pgoutput-parser` and turns tuple payloads into application-friendly Ruby row-change events.

It does **not** parse PostgreSQL wire bytes and it does **not** open replication connections. Those concerns belong to lower-level parser and future client layers.

---

## Requirements

- Ruby 3.4+
- `pgoutput-parser` `~> 0.1`

---

## Architecture

```text
pgoutput-parser
      │
      ▼
Protocol messages
      │
      ▼
pgoutput-decoder
      │
      ▼
Decoded row-change events
```

---

## What This Gem Does

- Decodes PostgreSQL OID-backed tuple values
- Builds Ruby hashes from relation columns and tuple values
- Tracks relation metadata from `Relation` messages
- Tracks active transaction context from `Begin` / `Commit` messages
- Attaches `transaction_id` to DML events
- Returns immutable, Ractor-shareable event objects
- Supports custom OID decoders

---

## What This Gem Does Not Do

This gem intentionally does not:

- Parse PostgreSQL `CopyData` bytes
- Manage replication slots
- Open replication connections
- Maintain WAL acknowledgements
- Reconnect to PostgreSQL
- Publish events to queues
- Integrate with ActiveRecord

---

## Installation

```ruby
gem "pgoutput-decoder"
```

Then:

```bash
bundle install
```

Require it with:

```ruby
require "pgoutput/decoder"
```

---

## Quick Start

```ruby
require "pgoutput"
require "pgoutput/decoder"

stream = Pgoutput::RelationTracker.new
decoder = Pgoutput::Decoder.new

protocol_message = stream.process(payload)
event = decoder.decode(protocol_message)
```

A `Relation` message updates decoder metadata and returns `nil`:

```ruby
decoder.decode(relation_message)
# => nil
```

An insert message returns a decoded event:

```ruby
event = decoder.decode(insert_message)

event.transaction_id
# => 789

event.schema
# => "public"

event.table
# => "users"

event.values
# => { "id" => 7, "name" => "Alice", "active" => true }
```

---

## Transaction Context

PostgreSQL `pgoutput` carries the transaction ID in the `Begin` (`B`) message, not on every row-change message.

The decoder remembers the active transaction and attaches it to decoded DML events:

```ruby
decoder.decode(begin_message)
decoder.decode(relation_message)
insert = decoder.decode(insert_message)

insert.transaction_id
# => 789
```

The transaction ID is useful for grouping changes, debugging, and CDC processing. It should not be treated as a globally permanent identifier because PostgreSQL transaction IDs can wrap around.

---

## Supported Events

```ruby
Pgoutput::Decoder::Events::Begin
Pgoutput::Decoder::Events::Commit
Pgoutput::Decoder::Events::Insert
Pgoutput::Decoder::Events::Update
Pgoutput::Decoder::Events::Delete
```

---

## Default Type Support

The default registry supports common scalar PostgreSQL OIDs:

| OID  | Type             |
| ---- | ---------------- |
| 16   | boolean          |
| 20   | bigint           |
| 21   | smallint         |
| 23   | integer          |
| 25   | text             |
| 114  | json             |
| 700  | real             |
| 701  | double precision |
| 1043 | varchar          |
| 1082 | date             |
| 1114 | timestamp        |
| 1184 | timestamptz      |
| 1700 | numeric          |
| 2950 | uuid             |
| 3802 | jsonb            |

Unsupported OIDs are returned as frozen raw strings.

---

## Binary Values

Binary decoding is intentionally conservative.

The decoder handles safe fixed-width binary scalar types such as:

- boolean
- int2
- int4
- int8
- float4
- float8

Unsupported binary values are preserved as frozen raw bytes.

---

## Custom OID Decoders

```ruby
registry =
  Pgoutput::Decoder::TypeRegistry.default.with_decoder(999_999) do |raw, format|
    format == :text ? "custom:#{raw}" : raw
  end

decoder = Pgoutput::Decoder.new(type_registry: registry)
```

---

## Update Events

```ruby
update = decoder.decode(update_message)

update.old_key
# => { "id" => 7 } or nil

update.old_values
# => { ... } or nil

update.new_values
# => { "id" => 7, "name" => "Bob" }
```

---

## Delete Events

```ruby
delete = decoder.decode(delete_message)

delete.old_key
# => { "id" => 7 } or nil

delete.old_values
# => { ... } or nil
```

`old_key` contains only columns marked as replica-key columns by the preceding
`Relation` message. Composite and non-`id` identities retain their declared
column order; full-width tuples with non-key placeholders do not leak those
placeholders into the decoded key.

---

## Ractor Safety

Decoded events are deeply shareable:

```ruby
event = decoder.decode(update_message)

Ractor.shareable?(event)
# => true
```

The decoder instance itself is stateful and should not be shared across Ractors.

---

## Testing

```bash
bundle exec rake test
```

The test task generates line and branch coverage in `coverage/` and enforces
the configured minimums:

```bash
bundle exec rake test
```

---

## Type Checking

```bash
bundle exec steep check
```

---

## License

[MIT](LICENSE.txt).
