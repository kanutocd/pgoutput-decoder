# frozen_string_literal: true

begin
  require "pgoutput"
rescue LoadError
  # The runtime dependency is provided by the installed gem.
end

require_relative "decoder/version"
require_relative "decoder/errors"

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
  end
end
