# frozen_string_literal: true

module Pgoutput
  module Messages
    Begin = Data.define(:final_lsn, :commit_timestamp, :xid) unless const_defined?(:Begin)
    Column = Data.define(:flags, :name, :oid, :type_modifier) unless const_defined?(:Column)
    Relation = Data.define(:relation_id, :schema, :table, :replica_identity, :columns) unless const_defined?(:Relation)
    TupleValue = Data.define(:format, :raw, :oid) unless const_defined?(:TupleValue)
    Insert = Data.define(:relation_id, :tuple) unless const_defined?(:Insert)
    Update = Data.define(:relation_id, :old_key_tuple, :old_tuple, :new_tuple) unless const_defined?(:Update)
    Delete = Data.define(:relation_id, :old_key_tuple, :old_tuple) unless const_defined?(:Delete)
    Commit = Data.define(:flags, :commit_lsn, :transaction_end_lsn, :commit_timestamp) unless const_defined?(:Commit)
  end
end
