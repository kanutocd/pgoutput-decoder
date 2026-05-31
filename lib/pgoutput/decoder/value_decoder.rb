# frozen_string_literal: true

module Pgoutput
  class Decoder
    # Decodes one pgoutput-parser TupleValue using a TypeRegistry.
    #
    # @api public
    class ValueDecoder
      # @param type_registry [TypeRegistry]
      # @return [void]
      def initialize(type_registry: TypeRegistry.default)
        @type_registry = type_registry
        freeze
      end

      # Decode one tuple value.
      #
      # @param tuple_value [Pgoutput::Messages::TupleValue]
      # @return [Object, nil, Symbol]
      def decode(tuple_value)
        case tuple_value.format
        when :null
          nil
        when :unchanged_toast
          :unchanged_toast
        when :text, :binary
          @type_registry.decode(tuple_value.oid, tuple_value.raw, tuple_value.format)
        else
          raise ValueDecodeError, "unsupported tuple value format: #{tuple_value.format.inspect}"
        end
      end
    end
  end
end
