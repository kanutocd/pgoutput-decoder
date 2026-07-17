# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/builders"

class DecoderIntegrationTest < Minitest::Test
  include Builders

  def test_decodes_begin_insert_update_delete_commit_with_transaction_context
    decoder = Pgoutput::Decoder.new

    begin_event = decoder.decode(begin_msg)
    relation_event = decoder.decode(relation_msg)
    insert_event = decoder.decode(insert_msg)
    update_event = decoder.decode(update_msg)
    delete_event = decoder.decode(delete_msg)
    commit_event = decoder.decode(commit_msg)
    events = [begin_event, insert_event, update_event, delete_event, commit_event]

    assert_nil relation_event
    assert_equal [789, 789, 789, 789, 789], events.map(&:transaction_id)
    assert_equal(
      [
        { "id" => 7, "name" => "Alice", "active" => true },
        { "id" => 7 },
        { "id" => 7, "name" => "Bob", "active" => true },
        { "id" => 7 },
        true
      ],
      [insert_event.values, update_event.old_key, update_event.new_values, delete_event.old_key,
       events.all? { |event| Ractor.shareable?(event) }]
    )
  end

  def test_dml_before_begin_raises
    decoder = Pgoutput::Decoder.new
    decoder.decode(relation_msg)

    assert_raises(Pgoutput::Decoder::TransactionStateError) do
      decoder.decode(insert_msg)
    end
  end

  def test_unknown_relation_raises
    decoder = Pgoutput::Decoder.new
    decoder.decode(begin_msg)

    assert_raises(Pgoutput::Decoder::UnknownRelationError) do
      decoder.decode(insert_msg)
    end
  end

  def test_ractor_handoff_safety
    decoder = Pgoutput::Decoder.new
    decoder.decode(begin_msg)
    decoder.decode(relation_msg)
    event = decoder.decode(update_msg)

    ractor = Ractor.new(event) do |message|
      [message.transaction_id, message.new_values["name"]]
    end

    result = if ractor.respond_to?(:value)
               ractor.value
             else
               ractor.take
             end

    assert_equal [789, "Bob"], result
  end
end
