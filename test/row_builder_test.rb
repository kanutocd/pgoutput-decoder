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

  def test_builds_composite_key_from_full_width_tuple_and_omits_non_key_placeholders
    relation = composite_relation
    tuple = [
      Pgoutput::Messages::TupleValue.new(:text, "9", nil),
      Pgoutput::Messages::TupleValue.new(:null, nil, nil),
      Pgoutput::Messages::TupleValue.new(:text, "member-1", nil)
    ].freeze

    key = Pgoutput::Decoder::RowBuilder.new.build_key(relation, tuple)

    assert_equal({ "tenant_id" => 9, "member_uuid" => "member-1" }, key)
    assert Ractor.shareable?(key)
  end

  def test_builds_compact_key_tuple_in_relation_key_order
    relation = composite_relation
    tuple = [
      Pgoutput::Messages::TupleValue.new(:text, "9", nil),
      Pgoutput::Messages::TupleValue.new(:text, "member-1", nil)
    ].freeze

    key = Pgoutput::Decoder::RowBuilder.new.build_key(relation, tuple)

    assert_equal({ "tenant_id" => 9, "member_uuid" => "member-1" }, key)
  end

  private

  def composite_relation
    Pgoutput::Messages::Relation.new(
      77,
      "public",
      "memberships",
      100,
      [
        Pgoutput::Messages::Column.new(1, "tenant_id", Pgoutput::Decoder::TypeRegistry::INT8, -1),
        Pgoutput::Messages::Column.new(0, "status", Pgoutput::Decoder::TypeRegistry::TEXT, -1),
        Pgoutput::Messages::Column.new(1, "member_uuid", Pgoutput::Decoder::TypeRegistry::TEXT, -1)
      ].freeze
    )
  end
end
