$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "prettyrb"

require "minitest/autorun"

def parse_source(source)
  Parser::CurrentRuby.parse_with_comments(source)[0]
end
