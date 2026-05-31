# frozen_string_literal: true

if ENV["COVERAGE"] == "true"
  require "simplecov"
  SimpleCov.start do
    enable_coverage :branch
    add_filter "/test/"
  end
end

require "minitest/autorun"
require_relative "../lib/pgoutput-decoder"
require_relative "support/parser_messages"
