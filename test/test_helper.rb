# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "pgoutput_decoder"
require_relative "support/parser_messages"
