# frozen_string_literal: true

module Pgoutput
  class Decoder
    # Immutable PostgreSQL OID-to-decoder registry.
    #
    # The registry maps OIDs to callable decoders. It is intentionally separate
    # from pgoutput-parser so the parser remains a pure protocol layer.
    #
    # @api public
    class TypeRegistry
      BOOL = 16
      INT8 = 20
      INT2 = 21
      INT4 = 23
      TEXT = 25
      JSON = 114
      FLOAT4 = 700
      FLOAT8 = 701
      VARCHAR = 1043
      DATE = 1082
      TIMESTAMP = 1114
      TIMESTAMPTZ = 1184
      NUMERIC = 1700
      UUID = 2950
      JSONB = 3802

      # @return [TypeRegistry] default immutable registry.
      def self.default
        @default ||= new(default_decoders)
      end

      # @return [Hash<Integer, Proc>] default decoder table.
      def self.default_decoders
        {
          BOOL => ->(raw, format) { decode_bool(raw, format) },
          INT2 => ->(raw, format) { decode_int(raw, format, 2, "s>") },
          INT4 => ->(raw, format) { decode_int(raw, format, 4, "l>") },
          INT8 => ->(raw, format) { decode_int(raw, format, 8, "q>") },
          TEXT => ->(raw, _format) { raw.dup.freeze },
          VARCHAR => ->(raw, _format) { raw.dup.freeze },
          FLOAT4 => ->(raw, format) { decode_float(raw, format, 4, "g") },
          FLOAT8 => ->(raw, format) { decode_float(raw, format, 8, "G") },
          NUMERIC => ->(raw, format) { format == :text ? BigDecimal(raw) : raw.dup.freeze },
          JSON => ->(raw, format) { format == :text ? ::JSON.parse(raw) : raw.dup.freeze },
          JSONB => ->(raw, format) { decode_jsonb(raw, format) },
          UUID => ->(raw, format) { format == :text ? raw.dup.freeze : decode_uuid_binary(raw) },
          DATE => ->(raw, format) { format == :text ? Date.iso8601(raw) : raw.dup.freeze },
          TIMESTAMP => ->(raw, format) { format == :text ? Time.parse(raw) : raw.dup.freeze },
          TIMESTAMPTZ => ->(raw, format) { format == :text ? Time.parse(raw) : raw.dup.freeze }
        }.freeze
      end

      # @param decoders [Hash<Integer, Proc>] decoder table.
      # @return [void]
      def initialize(decoders = self.class.default_decoders)
        @decoders = decoders.dup.freeze
        freeze
      end

      # Decode a raw tuple payload.
      #
      # @param oid [Integer, nil] PostgreSQL type OID.
      # @param raw [String, nil] raw payload.
      # @param format [Symbol] tuple value format.
      # @return [Object, nil]
      def decode(oid, raw, format)
        return nil if raw.nil?

        decoder = @decoders[oid]
        decoded = decoder ? decoder.call(raw, format) : raw.dup.freeze
        Ractor.make_shareable(decoded)
      end

      # Create a new registry with one custom decoder.
      #
      # @param oid [Integer] PostgreSQL type OID.
      # @yieldparam raw [String] raw payload.
      # @yieldparam format [Symbol] tuple value format.
      # @yieldreturn [Object]
      # @return [TypeRegistry]
      def with_decoder(oid, &block)
        raise ArgumentError, "block required" unless block

        self.class.new(@decoders.merge(Integer(oid) => block))
      end

      class << self
        private

        def decode_bool(raw, format)
          return raw == "t" if format == :text

          raw.unpack1("C") == 1
        end

        def decode_int(raw, format, expected_length, template)
          return raw.to_i if format == :text
          return raw.dup.freeze unless raw.bytesize == expected_length

          raw.unpack1(template)
        end

        def decode_float(raw, format, expected_length, template)
          return Float(raw) if format == :text
          return raw.dup.freeze unless raw.bytesize == expected_length

          raw.unpack1(template)
        end

        def decode_jsonb(raw, format)
          return ::JSON.parse(raw) if format == :text

          # PostgreSQL binary jsonb starts with a version byte. Version 1 is the
          # current on-wire format; the remaining bytes contain JSON text.
          return raw.dup.freeze unless raw.bytesize >= 2 && raw.getbyte(0) == 1

          ::JSON.parse(raw.byteslice(1..))
        end

        def decode_uuid_binary(raw)
          return raw.dup.freeze unless raw.bytesize == 16

          hex = raw.unpack1("H*")
          "#{hex[0, 8]}-#{hex[8, 4]}-#{hex[12, 4]}-#{hex[16, 4]}-#{hex[20, 12]}".freeze
        end
      end
    end
  end
end
