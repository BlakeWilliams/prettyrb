require "simplecov"
SimpleCov.start

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "prettyrb"

require "minitest/autorun"

def assert_code_formatted(expected, source, skip_rstrip: false)
  result = Prettyrb::Formatter.new(source).format
  if skip_rstrip
    assert_equal expected, result, result
  else
    assert_equal expected.rstrip, result, result
  end
end
