# frozen_string_literal: true

require_relative "test_helper"

class ValueDecoderTest < Minitest::Test
  def test_decodes_null
    value = Pgoutput::Messages::TupleValue.new(:null, nil, 23)

    assert_nil Pgoutput::Decoder::ValueDecoder.new.decode(value)
  end

  def test_decodes_unchanged_toast
    value = Pgoutput::Messages::TupleValue.new(:unchanged_toast, nil, 25)

    assert_equal :unchanged_toast, Pgoutput::Decoder::ValueDecoder.new.decode(value)
  end

  def test_decodes_text_using_registry
    value = Pgoutput::Messages::TupleValue.new(:text, "7", Pgoutput::Decoder::TypeRegistry::INT4)

    assert_equal 7, Pgoutput::Decoder::ValueDecoder.new.decode(value)
  end

  def test_decodes_binary_using_registry
    value = Pgoutput::Messages::TupleValue.new(:binary, [7].pack("l>"), Pgoutput::Decoder::TypeRegistry::INT4)

    assert_equal 7, Pgoutput::Decoder::ValueDecoder.new.decode(value)
  end

  def test_rejects_unknown_tuple_format
    value = Pgoutput::Messages::TupleValue.new(:weird, "x", 25)

    assert_raises(Pgoutput::Decoder::ValueDecodeError) do
      Pgoutput::Decoder::ValueDecoder.new.decode(value)
    end
  end
end
