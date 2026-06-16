# frozen_string_literal: true

require "simplecov"

SimpleCov.external_at_exit = true
SimpleCov.start do
  enable_coverage :branch
  track_files "lib/**/*.rb"
  add_filter "/test/"
  minimum_coverage line: 95, branch: 95
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "pgoutput_decoder"
require_relative "support/parser_messages"
