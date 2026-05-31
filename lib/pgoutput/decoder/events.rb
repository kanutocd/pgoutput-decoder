# frozen_string_literal: true

module Pgoutput
  class Decoder
    # Immutable decoded event objects returned by Pgoutput::Decoder.
    module Events
      # Decoded transaction begin event.
      Begin = Data.define(:transaction_id, :final_lsn, :commit_timestamp)

      # Decoded transaction commit event.
      Commit = Data.define(
        :transaction_id,
        :flags,
        :commit_lsn,
        :transaction_end_lsn,
        :commit_timestamp
      )

      # Decoded insert row-change event.
      Insert = Data.define(:transaction_id, :relation_id, :schema, :table, :values)

      # Decoded update row-change event.
      Update = Data.define(
        :transaction_id,
        :relation_id,
        :schema,
        :table,
        :old_key,
        :old_values,
        :new_values
      )

      # Decoded delete row-change event.
      Delete = Data.define(:transaction_id, :relation_id, :schema, :table, :old_key, :old_values)
    end
  end
end
