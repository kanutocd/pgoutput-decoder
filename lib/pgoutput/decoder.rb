# frozen_string_literal: true

begin
  require "pgoutput"
rescue LoadError
  # The runtime dependency is provided by the installed gem.
end

require_relative "decoder/version"
require_relative "decoder/errors"
require_relative "decoder/events"
require_relative "decoder/type_registry"

module Pgoutput
  # Stateful high-level decoder for pgoutput-parser protocol messages.
  #
  # Decoder accepts immutable protocol messages from pgoutput-parser and returns
  # immutable, Ractor-shareable row-change events. The decoder maintains relation
  # and active transaction context, so one instance should be used per logical
  # replication stream.
  #
  # @api public
  class Decoder
    # @return [TypeRegistry]
    attr_reader :type_registry

    # @param type_registry [TypeRegistry] immutable OID decoder registry.
    # @return [void]
    def initialize(type_registry: TypeRegistry.default)
      @type_registry = type_registry
    end
  end
end
