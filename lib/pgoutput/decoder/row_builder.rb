# frozen_string_literal: true

module Pgoutput
  class Decoder
    # Builds decoded row hashes from Relation metadata and TupleValue arrays.
    #
    # @api public
    class RowBuilder
      # @param type_registry [TypeRegistry]
      # @return [void]
      def initialize(type_registry: TypeRegistry.default)
        @value_decoder = ValueDecoder.new(type_registry: type_registry)
        freeze
      end

      # Build a decoded row hash.
      #
      # @param relation [Pgoutput::Messages::Relation]
      # @param tuple [Array<Pgoutput::Messages::TupleValue>]
      # @return [Hash<String, Object>]
      def build(relation, tuple)
        build_columns(relation.columns, tuple)
      end

      # Build a decoded replica-key hash.
      #
      # PostgreSQL may encode an old-key tuple at full relation width with
      # placeholders for non-key columns, while compact protocol fixtures may
      # contain only key values. Relation flags determine the exact key columns
      # in both representations.
      #
      # @param relation [Pgoutput::Messages::Relation]
      # @param tuple [Array<Pgoutput::Messages::TupleValue>]
      # @return [Hash<String, Object>]
      def build_key(relation, tuple)
        key_columns = relation.columns.select { |column| key_column?(column) }
        columns = tuple.length == relation.columns.length ? relation.columns : key_columns
        build_columns(columns, tuple, key_only: true)
      end

      private

      def build_columns(columns, tuple, key_only: false)
        row = {} # : Hash[String, untyped]

        tuple.each_with_index do |tuple_value, index|
          column = columns[index]
          next unless column
          next if key_only && !key_column?(column)

          normalized_value = normalize_oid(tuple_value, column.oid)
          row[column.name] = @value_decoder.decode(normalized_value)
        end

        Ractor.make_shareable(row.freeze)
      end

      def key_column?(column)
        column.flags.allbits?(1)
      end

      def normalize_oid(tuple_value, oid)
        return tuple_value unless tuple_value.oid.nil?

        Pgoutput::Messages::TupleValue.new(tuple_value.format, tuple_value.raw, oid)
      end
    end
  end
end
