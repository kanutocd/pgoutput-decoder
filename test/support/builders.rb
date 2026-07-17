# frozen_string_literal: true

module Builders
  module_function

  def begin_msg
    Pgoutput::Messages::Begin.new(100, 1_748_678_400_000_000, 789)
  end

  def commit_msg
    Pgoutput::Messages::Commit.new(0, 110, 120, 1_748_678_401_000_000)
  end

  def relation_msg
    Pgoutput::Messages::Relation.new(
      42,
      "public",
      "users",
      100,
      [
        Pgoutput::Messages::Column.new(1, "id", Pgoutput::Decoder::TypeRegistry::INT4, -1),
        Pgoutput::Messages::Column.new(0, "name", Pgoutput::Decoder::TypeRegistry::TEXT, -1),
        Pgoutput::Messages::Column.new(0, "active", Pgoutput::Decoder::TypeRegistry::BOOL, -1)
      ].freeze
    )
  end

  def insert_msg
    Pgoutput::Messages::Insert.new(
      42,
      [
        Pgoutput::Messages::TupleValue.new(:text, "7", 23),
        Pgoutput::Messages::TupleValue.new(:text, "Alice", 25),
        Pgoutput::Messages::TupleValue.new(:text, "t", 16)
      ].freeze
    )
  end

  def update_msg
    Pgoutput::Messages::Update.new(
      42,
      [
        Pgoutput::Messages::TupleValue.new(:text, "7", 23),
        Pgoutput::Messages::TupleValue.new(:null, nil, nil),
        Pgoutput::Messages::TupleValue.new(:null, nil, nil)
      ].freeze,
      nil,
      [
        Pgoutput::Messages::TupleValue.new(:text, "7", 23),
        Pgoutput::Messages::TupleValue.new(:text, "Bob", 25),
        Pgoutput::Messages::TupleValue.new(:text, "t", 16)
      ].freeze
    )
  end

  def delete_msg
    Pgoutput::Messages::Delete.new(
      42,
      [
        Pgoutput::Messages::TupleValue.new(:text, "7", 23),
        Pgoutput::Messages::TupleValue.new(:null, nil, nil),
        Pgoutput::Messages::TupleValue.new(:null, nil, nil)
      ].freeze,
      nil
    )
  end
end
