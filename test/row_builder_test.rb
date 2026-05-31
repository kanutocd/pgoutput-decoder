# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/builders"

class RowBuilderTest < Minitest::Test
  include Builders

  def test_builds_shareable_row_and_normalizes_missing_oids_from_relation
    relation = relation_msg
    tuple = [
      Pgoutput::Messages::TupleValue.new(:text, "7", nil),
      Pgoutput::Messages::TupleValue.new(:text, "Alice", nil),
      Pgoutput::Messages::TupleValue.new(:text, "t", nil)
    ].freeze

    row = Pgoutput::Decoder::RowBuilder.new.build(relation, tuple)

    assert_equal({ "id" => 7, "name" => "Alice", "active" => true }, row)
    assert Ractor.shareable?(row)
  end

  def test_ignores_tuple_values_without_matching_relation_column
    relation = relation_msg
    tuple = [
      Pgoutput::Messages::TupleValue.new(:text, "7", 23),
      Pgoutput::Messages::TupleValue.new(:text, "Alice", 25),
      Pgoutput::Messages::TupleValue.new(:text, "t", 16),
      Pgoutput::Messages::TupleValue.new(:text, "ignored", 25)
    ].freeze

    row = Pgoutput::Decoder::RowBuilder.new.build(relation, tuple)

    assert_equal %w[id name active], row.keys
    refute_includes row.keys, "ignored"
  end
end
