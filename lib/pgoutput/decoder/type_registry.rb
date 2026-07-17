# frozen_string_literal: true

module Pgoutput
  class Decoder
    # Immutable PostgreSQL OID-to-decoder registry.
    #
    # The registry maps PostgreSQL type OIDs to callable decoders. It is
    # intentionally separate from pgoutput-parser so the parser remains a pure
    # protocol layer and the decoder owns value conversion policy.
    #
    # Registry instances are immutable after construction. Decoded values are
    # passed through Ractor.make_shareable so caller-visible values can cross
    # Ractor boundaries safely when Ruby supports the value shape.
    #
    # @api public
    class TypeRegistry
      # PostgreSQL bool OID.
      BOOL = 16

      # PostgreSQL int8 / bigint OID.
      INT8 = 20

      # PostgreSQL int2 / smallint OID.
      INT2 = 21

      # PostgreSQL int4 / integer OID.
      INT4 = 23

      # PostgreSQL text OID.
      TEXT = 25

      # PostgreSQL json OID.
      JSON = 114

      # PostgreSQL float4 / real OID.
      FLOAT4 = 700

      # PostgreSQL float8 / double precision OID.
      FLOAT8 = 701

      # PostgreSQL varchar OID.
      VARCHAR = 1043

      # PostgreSQL date OID.
      DATE = 1082

      # PostgreSQL timestamp without time zone OID.
      TIMESTAMP = 1114

      # PostgreSQL timestamp with time zone OID.
      TIMESTAMPTZ = 1184

      # PostgreSQL numeric OID.
      NUMERIC = 1700

      # PostgreSQL uuid OID.
      UUID = 2950

      # PostgreSQL jsonb OID.
      JSONB = 3802

      # Return the process-local default immutable registry.
      #
      # @return [TypeRegistry] default immutable registry.
      def self.default
        @default ||= new(default_decoders)
      end

      # Build the default OID decoder table.
      #
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
          NUMERIC => ->(raw, format) { format == :text ? Kernel.BigDecimal(raw) : raw.dup.freeze },
          JSON => ->(raw, format) { format == :text ? ::JSON.parse(raw) : raw.dup.freeze },
          JSONB => ->(raw, format) { decode_jsonb(raw, format) },
          UUID => ->(raw, format) { format == :text ? raw.dup.freeze : decode_uuid_binary(raw) },
          DATE => ->(raw, format) { format == :text ? Date.iso8601(raw) : raw.dup.freeze },
          TIMESTAMP => ->(raw, format) { format == :text ? Time.parse(raw) : raw.dup.freeze },
          TIMESTAMPTZ => ->(raw, format) { format == :text ? Time.parse(raw) : raw.dup.freeze }
        }.freeze
      end

      # Create an immutable registry.
      #
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

        decoder = oid ? @decoders[oid] : nil
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
      # @raise [ArgumentError] if no block is provided.
      def with_decoder(oid, &block)
        raise ArgumentError, "block required" unless block

        self.class.new(@decoders.merge(Integer(oid) => block))
      end

      class << self
        private

        # This decodes a PostgreSQL boolean value; it is not an object predicate.
        # rubocop:disable Naming/PredicateMethod
        def decode_bool(raw, format)
          return raw == "t" if format == :text

          raw.unpack1("C") == 1
        end
        # rubocop:enable Naming/PredicateMethod

        def decode_int(raw, format, expected_length, template)
          return raw.to_i if format == :text
          return raw.dup.freeze unless raw.bytesize == expected_length

          Integer(raw.unpack1(template))
        end

        def decode_float(raw, format, expected_length, template)
          return Float(raw) if format == :text
          return raw.dup.freeze unless raw.bytesize == expected_length

          Float(raw.unpack1(template))
        end

        def decode_jsonb(raw, format)
          return ::JSON.parse(raw) if format == :text

          # PostgreSQL binary jsonb starts with a version byte. Version 1 is the
          # current on-wire format; the remaining bytes contain JSON text.
          return raw.dup.freeze unless raw.bytesize >= 2 && raw.getbyte(0) == 1

          ::JSON.parse(raw.byteslice(1..).to_s)
        end

        def decode_uuid_binary(raw)
          return raw.dup.freeze unless raw.bytesize == 16

          hex = raw.unpack1("H*").to_s
          "#{hex[0, 8]}-#{hex[8, 4]}-#{hex[12, 4]}-#{hex[16, 4]}-#{hex[20, 12]}".freeze
        end
      end
    end
  end
end
