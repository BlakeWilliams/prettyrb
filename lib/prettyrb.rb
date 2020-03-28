require "parser/current"
require "prettyrb/version"

require "prettyrb/formatter"
require "prettyrb/formatters/base"
require "prettyrb/formatters/and"
require "prettyrb/formatters/array"
require "prettyrb/formatters/begin"
require "prettyrb/formatters/call"
require "prettyrb/formatters/casign"
require "prettyrb/formatters/class"
require "prettyrb/formatters/if"
require "prettyrb/formatters/lit"
require "prettyrb/formatters/or"
require "prettyrb/formatters/string"

module Prettyrb
  class Error < StandardError; end
end
