# frozen_string_literal: true

require_relative "test_helper"

class EventsTest < Minitest::Test
  def test_event_data_classes_are_available
    assert_equal 1, Pgoutput::Decoder::Events::Begin.new(1, 2, 3).transaction_id
    assert_equal 1, Pgoutput::Decoder::Events::Commit.new(1, 0, 2, 3, 4).transaction_id
    assert_equal "users", Pgoutput::Decoder::Events::Insert.new(1, 42, "public", "users", {}).table
    assert_equal({}, Pgoutput::Decoder::Events::Update.new(1, 42, "public", "users", nil, nil, {}).new_values)
    assert_nil Pgoutput::Decoder::Events::Delete.new(1, 42, "public", "users", nil, nil).old_values
  end
end
