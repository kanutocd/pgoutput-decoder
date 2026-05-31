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
      "public".freeze,
      "users".freeze,
      100,
      [
        Pgoutput::Messages::Column.new(1, "id".freeze, Pgoutput::Decoder::TypeRegistry::INT4, -1),
        Pgoutput::Messages::Column.new(0, "name".freeze, Pgoutput::Decoder::TypeRegistry::TEXT, -1),
        Pgoutput::Messages::Column.new(0, "active".freeze, Pgoutput::Decoder::TypeRegistry::BOOL, -1)
      ].freeze
    )
  end

  def insert_msg
    Pgoutput::Messages::Insert.new(
      42,
      [
        Pgoutput::Messages::TupleValue.new(:text, "7".freeze, 23),
        Pgoutput::Messages::TupleValue.new(:text, "Alice".freeze, 25),
        Pgoutput::Messages::TupleValue.new(:text, "t".freeze, 16)
      ].freeze
    )
  end

  def update_msg
    Pgoutput::Messages::Update.new(
      42,
      [Pgoutput::Messages::TupleValue.new(:text, "7".freeze, 23)].freeze,
      nil,
      [
        Pgoutput::Messages::TupleValue.new(:text, "7".freeze, 23),
        Pgoutput::Messages::TupleValue.new(:text, "Bob".freeze, 25),
        Pgoutput::Messages::TupleValue.new(:text, "t".freeze, 16)
      ].freeze
    )
  end

  def delete_msg
    Pgoutput::Messages::Delete.new(
      42,
      [Pgoutput::Messages::TupleValue.new(:text, "7".freeze, 23)].freeze,
      nil
    )
  end
end
