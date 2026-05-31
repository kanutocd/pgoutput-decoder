# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/builders"

class DecoderEdgeTest < Minitest::Test
  include Builders

  def test_unsupported_message_raises
    assert_raises(Pgoutput::Decoder::UnsupportedMessageError) do
      Pgoutput::Decoder.new.decode(Object.new)
    end
  end

  def test_commit_clears_transaction_context
    decoder = Pgoutput::Decoder.new
    decoder.decode(begin_msg)
    decoder.decode(relation_msg)
    decoder.decode(commit_msg)

    assert_raises(Pgoutput::Decoder::TransactionStateError) do
      decoder.decode(insert_msg)
    end
  end

  def test_commit_without_begin_is_allowed_with_nil_transaction_id
    event = Pgoutput::Decoder.new.decode(commit_msg)

    assert_nil event.transaction_id
    assert_equal 110, event.commit_lsn
    assert Ractor.shareable?(event)
  end

  def test_update_with_full_old_tuple
    decoder = Pgoutput::Decoder.new
    decoder.decode(begin_msg)
    decoder.decode(relation_msg)

    message = Pgoutput::Messages::Update.new(
      42,
      nil,
      [
        Pgoutput::Messages::TupleValue.new(:text, "7", 23),
        Pgoutput::Messages::TupleValue.new(:text, "Alice", 25),
        Pgoutput::Messages::TupleValue.new(:text, "f", 16)
      ].freeze,
      [
        Pgoutput::Messages::TupleValue.new(:text, "7", 23),
        Pgoutput::Messages::TupleValue.new(:text, "Bob", 25),
        Pgoutput::Messages::TupleValue.new(:text, "t", 16)
      ].freeze
    )

    event = decoder.decode(message)

    assert_nil event.old_key
    assert_equal({ "id" => 7, "name" => "Alice", "active" => false }, event.old_values)
    assert_equal({ "id" => 7, "name" => "Bob", "active" => true }, event.new_values)
  end

  def test_delete_with_full_old_tuple
    decoder = Pgoutput::Decoder.new
    decoder.decode(begin_msg)
    decoder.decode(relation_msg)

    message = Pgoutput::Messages::Delete.new(
      42,
      nil,
      [
        Pgoutput::Messages::TupleValue.new(:text, "7", 23),
        Pgoutput::Messages::TupleValue.new(:text, "Alice", 25),
        Pgoutput::Messages::TupleValue.new(:text, "f", 16)
      ].freeze
    )

    event = decoder.decode(message)

    assert_nil event.old_key
    assert_equal({ "id" => 7, "name" => "Alice", "active" => false }, event.old_values)
  end
end
