# frozen_string_literal: true

require_relative "test_helper"

class TypeRegistryTest < Minitest::Test
  def test_decodes_common_text_values
    registry = Pgoutput::Decoder::TypeRegistry.default

    assert_equal true, registry.decode(16, "t", :text)
    assert_equal false, registry.decode(16, "f", :text)
    assert_equal 7, registry.decode(23, "7", :text)
    assert_equal "Alice", registry.decode(25, "Alice", :text)
    assert_in_delta 3.14, registry.decode(701, "3.14", :text)
    assert_equal({ "a" => 1 }, registry.decode(114, '{"a":1}', :text))
  end

  def test_decodes_conservative_binary_values
    registry = Pgoutput::Decoder::TypeRegistry.default

    assert_equal true, registry.decode(16, [1].pack("C"), :binary)
    assert_equal 7, registry.decode(23, [7].pack("l>"), :binary)
    assert_in_delta 3.5, registry.decode(701, [3.5].pack("G"), :binary)
  end

  def test_unknown_oid_returns_frozen_raw_payload
    value = Pgoutput::Decoder::TypeRegistry.default.decode(999_999, "raw", :text)

    assert_equal "raw", value
    assert_predicate value, :frozen?
  end

  def test_custom_decoder
    registry = Pgoutput::Decoder::TypeRegistry.default.with_decoder(999) do |raw, _format|
      "custom:#{raw}".freeze
    end

    assert_equal "custom:x", registry.decode(999, "x", :text)
  end
end
