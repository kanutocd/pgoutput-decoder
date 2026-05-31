# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/builders"

class RowBuilderTest < Minitest::Test
  include Builders

  def test_builds_decoded_row
    row = Pgoutput::Decoder::RowBuilder.new.build(relation_msg, insert_msg.tuple)

    assert_equal({ "id" => 7, "name" => "Alice", "active" => true }, row)
    assert Ractor.shareable?(row)
  end

  def test_uses_relation_column_oid_when_tuple_oid_is_missing
    tuple = [Pgoutput::Messages::TupleValue.new(:text, "7", nil)].freeze
    row = Pgoutput::Decoder::RowBuilder.new.build(relation_msg, tuple)

    assert_equal 7, row["id"]
  end
end
