# frozen_string_literal: true

module Pgoutput
  class Decoder
    # Base decoder error.
    class Error < StandardError; end

    # Raised when a DML message references an unknown relation.
    class UnknownRelationError < Error; end

    # Raised when a message type cannot be decoded.
    class UnsupportedMessageError < Error; end

    # Raised when a value cannot be decoded for its PostgreSQL OID.
    class ValueDecodeError < Error; end

    # Raised when DML appears outside an active transaction.
    class TransactionStateError < Error; end
  end
end
