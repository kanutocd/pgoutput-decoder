# frozen_string_literal: true

require_relative "test_helper"

class TypeRegistryTest < Minitest::Test
  def setup
    @registry = Pgoutput::Decoder::TypeRegistry.default
  end

  def test_default_registry_is_memoized_and_immutable
    assert_same Pgoutput::Decoder::TypeRegistry.default, Pgoutput::Decoder::TypeRegistry.default
    assert_predicate @registry, :frozen?
  end

  def test_decode_nil_raw_returns_nil
    assert_nil @registry.decode(Pgoutput::Decoder::TypeRegistry::INT4, nil, :text)
  end

  def test_decodes_common_text_values
    assert_equal true, @registry.decode(Pgoutput::Decoder::TypeRegistry::BOOL, "t", :text)
    assert_equal false, @registry.decode(Pgoutput::Decoder::TypeRegistry::BOOL, "f", :text)
    assert_equal 2, @registry.decode(Pgoutput::Decoder::TypeRegistry::INT2, "2", :text)
    assert_equal 7, @registry.decode(Pgoutput::Decoder::TypeRegistry::INT4, "7", :text)
    assert_equal 9_000_000_000, @registry.decode(Pgoutput::Decoder::TypeRegistry::INT8, "9000000000", :text)
    assert_equal "Alice", @registry.decode(Pgoutput::Decoder::TypeRegistry::TEXT, "Alice", :text)
    assert_equal "Alice", @registry.decode(Pgoutput::Decoder::TypeRegistry::VARCHAR, "Alice", :text)
    assert_in_delta 3.25, @registry.decode(Pgoutput::Decoder::TypeRegistry::FLOAT4, "3.25", :text)
    assert_in_delta 3.14, @registry.decode(Pgoutput::Decoder::TypeRegistry::FLOAT8, "3.14", :text)
    assert_equal BigDecimal("12.34"), @registry.decode(Pgoutput::Decoder::TypeRegistry::NUMERIC, "12.34", :text)
    assert_equal({ "a" => 1 }, @registry.decode(Pgoutput::Decoder::TypeRegistry::JSON, '{"a":1}', :text))
    assert_equal({ "b" => 2 }, @registry.decode(Pgoutput::Decoder::TypeRegistry::JSONB, '{"b":2}', :text))
    assert_equal "550e8400-e29b-41d4-a716-446655440000",
                 @registry.decode(Pgoutput::Decoder::TypeRegistry::UUID, "550e8400-e29b-41d4-a716-446655440000", :text)
    assert_equal Date.new(2026, 5, 31), @registry.decode(Pgoutput::Decoder::TypeRegistry::DATE, "2026-05-31", :text)
    assert_equal 2026, @registry.decode(Pgoutput::Decoder::TypeRegistry::TIMESTAMP, "2026-05-31 12:34:56", :text).year
    assert_equal 2026,
                 @registry.decode(Pgoutput::Decoder::TypeRegistry::TIMESTAMPTZ, "2026-05-31 12:34:56 UTC", :text).year
  end

  def test_decodes_binary_values_when_supported
    assert_equal true, @registry.decode(Pgoutput::Decoder::TypeRegistry::BOOL, [1].pack("C"), :binary)
    assert_equal false, @registry.decode(Pgoutput::Decoder::TypeRegistry::BOOL, [0].pack("C"), :binary)
    assert_equal 2, @registry.decode(Pgoutput::Decoder::TypeRegistry::INT2, [2].pack("s>"), :binary)
    assert_equal 7, @registry.decode(Pgoutput::Decoder::TypeRegistry::INT4, [7].pack("l>"), :binary)
    assert_equal 9_000_000_000,
                 @registry.decode(Pgoutput::Decoder::TypeRegistry::INT8, [9_000_000_000].pack("q>"), :binary)
    assert_in_delta 3.25, @registry.decode(Pgoutput::Decoder::TypeRegistry::FLOAT4, [3.25].pack("g"), :binary)
    assert_in_delta 3.5, @registry.decode(Pgoutput::Decoder::TypeRegistry::FLOAT8, [3.5].pack("G"), :binary)
  end

  def test_binary_values_with_unsupported_or_invalid_lengths_return_frozen_raw
    [
      @registry.decode(Pgoutput::Decoder::TypeRegistry::INT2, "x", :binary),
      @registry.decode(Pgoutput::Decoder::TypeRegistry::INT4, "x", :binary),
      @registry.decode(Pgoutput::Decoder::TypeRegistry::INT8, "x", :binary),
      @registry.decode(Pgoutput::Decoder::TypeRegistry::FLOAT4, "x", :binary),
      @registry.decode(Pgoutput::Decoder::TypeRegistry::FLOAT8, "x", :binary),
      @registry.decode(Pgoutput::Decoder::TypeRegistry::NUMERIC, "12.34", :binary),
      @registry.decode(Pgoutput::Decoder::TypeRegistry::JSON, '{"a":1}', :binary),
      @registry.decode(Pgoutput::Decoder::TypeRegistry::DATE, "raw-date", :binary),
      @registry.decode(Pgoutput::Decoder::TypeRegistry::TIMESTAMP, "raw-ts", :binary),
      @registry.decode(Pgoutput::Decoder::TypeRegistry::TIMESTAMPTZ, "raw-tstz", :binary)
    ].each do |value|
      assert_predicate value, :frozen?
    end
  end

  def test_decodes_binary_jsonb_version_one
    value = @registry.decode(Pgoutput::Decoder::TypeRegistry::JSONB, '{"ok":true}', :binary)

    assert_equal({ "ok" => true }, value)
  end

  def test_invalid_binary_jsonb_returns_frozen_raw
    value = @registry.decode(Pgoutput::Decoder::TypeRegistry::JSONB, "\u0002{}", :binary)

    assert_equal "\u0002{}", value
    assert_predicate value, :frozen?
  end

  def test_decodes_binary_uuid_when_length_is_valid
    raw = ["550e8400e29b41d4a716446655440000"].pack("H*")

    assert_equal "550e8400-e29b-41d4-a716-446655440000",
                 @registry.decode(Pgoutput::Decoder::TypeRegistry::UUID, raw, :binary)
  end

  def test_invalid_binary_uuid_returns_frozen_raw
    value = @registry.decode(Pgoutput::Decoder::TypeRegistry::UUID, "short", :binary)

    assert_equal "short", value
    assert_predicate value, :frozen?
  end

  def test_unknown_oid_returns_frozen_raw_payload
    value = @registry.decode(999_999, "raw", :text)

    assert_equal "raw", value
    assert_predicate value, :frozen?
  end

  def test_custom_decoder
    registry = @registry.with_decoder(999) do |raw, _format|
      "custom:#{raw}".freeze
    end

    assert_equal "custom:x", registry.decode(999, "x", :text)
  end

  def test_custom_decoder_requires_block
    assert_raises(ArgumentError) { @registry.with_decoder(999) }
  end
end
