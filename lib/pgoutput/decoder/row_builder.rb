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
        row = {} # : Hash[String, untyped]

        tuple.each_with_index do |tuple_value, index|
          column = relation.columns[index]
          next unless column

          normalized_value = normalize_oid(tuple_value, column.oid)
          row[column.name] = @value_decoder.decode(normalized_value)
        end

        Ractor.make_shareable(row.freeze)
      end

      private

      def normalize_oid(tuple_value, oid)
        return tuple_value unless tuple_value.oid.nil?

        Pgoutput::Messages::TupleValue.new(tuple_value.format, tuple_value.raw, oid)
      end
    end
  end
end
