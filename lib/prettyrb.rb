require "forwardable"

require "parser/current"
require "prettyrb/version"

require "prettyrb/nodes/base_node"
require "prettyrb/nodes/if_node"
require "prettyrb/nodes/string_helper"
require "prettyrb/nodes/str_node"
require "prettyrb/nodes/dstr_node"
require "prettyrb/nodes/regexp_node"
require "prettyrb/nodes/send_node"
require "prettyrb/correcter/base"
require "prettyrb/correcter/heredoc_in_method"
require "prettyrb/correcter/heredoc_method_chain"
require "prettyrb/builder"
require "prettyrb/formatter"
require "prettyrb/visitor"

require "prettyrb/cli"

module Prettyrb
  class Error < StandardError; end
end
