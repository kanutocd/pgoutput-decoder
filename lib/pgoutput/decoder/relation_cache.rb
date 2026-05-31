# frozen_string_literal: true

module Pgoutput
  class Decoder
    # Mutable per-stream cache of pgoutput-parser Relation messages.
    #
    # @api public
    class RelationCache
      # @return [void]
      def initialize
        @relations = {} #: Hash[Integer, untyped]
      end

      # Store a relation message.
      #
      # @param relation [Pgoutput::Messages::Relation]
      # @return [Pgoutput::Messages::Relation]
      def store(relation)
        @relations[relation.relation_id] = relation
      end

      # Fetch a relation message by id.
      #
      # @param relation_id [Integer]
      # @return [Pgoutput::Messages::Relation]
      # @raise [UnknownRelationError]
      def fetch(relation_id)
        @relations.fetch(relation_id) do
          raise UnknownRelationError, "unknown relation id #{relation_id}; decode Relation message first"
        end
      end
    end
  end
end
