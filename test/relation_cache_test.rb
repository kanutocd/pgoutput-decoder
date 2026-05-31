# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/builders"

class RelationCacheTest < Minitest::Test
  include Builders

  def test_store_and_fetch_relation
    cache = Pgoutput::Decoder::RelationCache.new
    relation = relation_msg

    assert_same relation, cache.store(relation)
    assert_same relation, cache.fetch(relation.relation_id)
  end

  def test_fetch_unknown_relation_raises
    cache = Pgoutput::Decoder::RelationCache.new

    assert_raises(Pgoutput::Decoder::UnknownRelationError) { cache.fetch(404) }
  end
end
