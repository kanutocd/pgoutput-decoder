# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/builders"

class RelationCacheTest < Minitest::Test
  include Builders

  def test_stores_and_fetches_relation
    cache = Pgoutput::Decoder::RelationCache.new
    relation = relation_msg

    cache.store(relation)

    assert_same relation, cache.fetch(42)
  end

  def test_unknown_relation_raises
    cache = Pgoutput::Decoder::RelationCache.new

    assert_raises(Pgoutput::Decoder::UnknownRelationError) do
      cache.fetch(42)
    end
  end
end
