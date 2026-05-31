# frozen_string_literal: true

module Pgoutput
  class Decoder
    # Immutable decoded event objects returned by Pgoutput::Decoder.
    #
    # These Data classes are intentionally value-oriented and are made shareable
    # by Pgoutput::Decoder before they are returned to callers.
    module Events
      # Decoded transaction begin event class.
      #
      # @return [Class]
      Begin = Data.define(:transaction_id, :final_lsn, :commit_timestamp)

      # Decoded transaction commit event class.
      #
      # @return [Class]
      Commit = Data.define(
        :transaction_id,
        :flags,
        :commit_lsn,
        :transaction_end_lsn,
        :commit_timestamp
      )

      # Decoded insert row-change event class.
      #
      # @return [Class]
      Insert = Data.define(:transaction_id, :relation_id, :schema, :table, :values)

      # Decoded update row-change event class.
      #
      # @return [Class]
      Update = Data.define(
        :transaction_id,
        :relation_id,
        :schema,
        :table,
        :old_key,
        :old_values,
        :new_values
      )

      # Decoded delete row-change event class.
      #
      # @return [Class]
      Delete = Data.define(:transaction_id, :relation_id, :schema, :table, :old_key, :old_values)
    end
  end
end
