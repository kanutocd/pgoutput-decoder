# frozen_string_literal: true

require "bigdecimal"
require "date"
require "json"
require "time"
require "pgoutput"

require_relative "decoder/version"
require_relative "decoder/errors"
require_relative "decoder/events"
require_relative "decoder/type_registry"
require_relative "decoder/value_decoder"
require_relative "decoder/relation_cache"
require_relative "decoder/row_builder"

module Pgoutput
  # Stateful high-level decoder for pgoutput-parser protocol messages.
  #
  # Decoder accepts immutable protocol messages from pgoutput-parser and returns
  # immutable, Ractor-shareable row-change events. The decoder maintains relation
  # and active transaction context, so one instance should be used per logical
  # replication stream.
  #
  # @api public
  class Decoder
    # @return [TypeRegistry]
    attr_reader :type_registry

    # @param type_registry [TypeRegistry] immutable OID decoder registry.
    # @return [void]
    def initialize(type_registry: TypeRegistry.default)
      @type_registry = type_registry
      @relations = RelationCache.new
      @row_builder = RowBuilder.new(type_registry: type_registry)
      @current_transaction_id = nil
      @current_final_lsn = nil
      @current_commit_timestamp = nil
    end

    # Decode one pgoutput-parser protocol message.
    #
    # @param message [Object] protocol message from pgoutput-parser.
    # @return [Events::Begin, Events::Commit, Events::Insert, Events::Update, Events::Delete, nil]
    # @raise [UnknownRelationError] if a DML message references an unknown relation.
    # @raise [TransactionStateError] if DML arrives before Begin.
    def decode(message)
      case message
      when parser_messages::Begin
        decode_begin(message)
      when parser_messages::Relation
        @relations.store(message)
        nil
      when parser_messages::Insert
        decode_insert(message)
      when parser_messages::Update
        decode_update(message)
      when parser_messages::Delete
        decode_delete(message)
      when parser_messages::Commit
        decode_commit(message)
      else
        raise UnsupportedMessageError, "unsupported message: #{message.class}"
      end
    end

    private

    def decode_begin(message)
      @current_transaction_id = message.xid
      @current_final_lsn = message.final_lsn
      @current_commit_timestamp = message.commit_timestamp

      share(
        Events::Begin.new(
          message.xid,
          message.final_lsn,
          message.commit_timestamp
        )
      )
    end

    def decode_commit(message)
      transaction_id = @current_transaction_id

      event = Events::Commit.new(
        transaction_id,
        message.flags,
        message.commit_lsn,
        message.transaction_end_lsn,
        message.commit_timestamp
      )

      clear_transaction!
      share(event)
    end

    def decode_insert(message)
      relation = relation_for(message.relation_id)
      transaction_id = require_transaction_id

      share(
        Events::Insert.new(
          transaction_id,
          message.relation_id,
          relation.schema,
          relation.table,
          @row_builder.build(relation, message.tuple)
        )
      )
    end

    def decode_update(message)
      relation = relation_for(message.relation_id)
      transaction_id = require_transaction_id

      share(
        Events::Update.new(
          transaction_id,
          message.relation_id,
          relation.schema,
          relation.table,
          optional_row(relation, message.old_key_tuple, key: true),
          optional_row(relation, message.old_tuple),
          @row_builder.build(relation, message.new_tuple)
        )
      )
    end

    def decode_delete(message)
      relation = relation_for(message.relation_id)
      transaction_id = require_transaction_id

      share(
        Events::Delete.new(
          transaction_id,
          message.relation_id,
          relation.schema,
          relation.table,
          optional_row(relation, message.old_key_tuple, key: true),
          optional_row(relation, message.old_tuple)
        )
      )
    end

    def optional_row(relation, tuple, key: false)
      return nil if tuple.nil?
      return @row_builder.build_key(relation, tuple) if key

      @row_builder.build(relation, tuple)
    end

    def relation_for(relation_id)
      @relations.fetch(relation_id)
    end

    def require_transaction_id
      @current_transaction_id || raise(TransactionStateError, "DML message received outside an active transaction")
    end

    def clear_transaction!
      @current_transaction_id = nil
      @current_final_lsn = nil
      @current_commit_timestamp = nil
    end

    def parser_messages
      Pgoutput::Messages
    end

    def share(object)
      Ractor.make_shareable(object)
    end
  end
end
