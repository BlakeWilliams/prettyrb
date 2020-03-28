require "parser/current"
require "prettyrb/version"

module Prettyrb
  class Error < StandardError; end

  class Formatter
    def self.for(node)
      case node.type
      when :if
        IfFormatter
      when :str
        StringFormatter
      when :or
        OrFormatter
      when :and
        AndFormatter
      when :int
        LitFormatter
      when :send
        CallFormatter
      when :class
        ClassFormatter
      when :casgn
        CassignFormatter
      when :array
        ArrayFormatter
      when :begin
        BeginFormatter
      else
        raise "can't handle #{node}"
      end
    end

    def initialize(code)
      @code = code
    end

    def format
      root_node, comments = Parser::CurrentRuby.parse_with_comments(@code)

      self.class.for(root_node).new(root_node, 0, nil).format
    end

    private

    def format_type(node, indentation)
      case node.node_type
      when :if
        IfFormatter.new(node, indentation).format
      else
        raise "can't handle #{node}"
      end
    end

    attr_reader :code
  end

  class BaseFormatter
    attr_reader :node, :indentation, :parent

    def initialize(node, indentation, parent)
      @node = node
      @indentation = indentation
      @parent = parent
    end

    def type
      node.type
    end

    def indents
      ' ' * indentation
    end
  end

  class LitFormatter < BaseFormatter
    def format
      node.children[0]
    end
  end

  class StringFormatter < BaseFormatter
    def format
      if parent.type == :array
        "\"#{node.children[0]}\""
      else
        "#{indents}\"#{node.children[0]}\""
      end
    end
  end

  class IfFormatter < BaseFormatter
    def format
      condition, body = node.children
      start = "#{indents}if "
      condition = Formatter.for(condition).new(condition, @indentation + 2, self).format
      body = Formatter.for(body).new(body, @indentation + 2, self).format
      ending = "#{indents}end"

      "#{start}#{condition}\n#{body}\n#{ending}"
    end
  end

  class OrFormatter < BaseFormatter
    def format
      left_node, right_node = node.children
      left = Formatter.for(left_node).new(left_node, @indentation, self).format
      right = Formatter.for(right_node).new(right_node, @indentation, self).format

      if needs_parens?
        "(#{left} || #{right})"
      else
        "#{left} || #{right}"
      end
    end

    private

    def needs_parens?
      parent&.type == :or || parent&.type == :and
    end
  end

  class AndFormatter < BaseFormatter
    def format
      left_node, right_node = node.children
      left = Formatter.for(left_node).new(left_node, @indentation, self).format
      right = Formatter.for(right_node).new(right_node, @indentation, self).format

      if needs_parens?
        "(#{left} && #{right})"
      else
        "#{left} && #{right}"
      end
    end

    private

    def needs_parens?
      parent&.type == :or || parent&.type == :and
    end
  end

  class CallFormatter < BaseFormatter
    def format
      if infix?
        left_node, operator, right_node = node.children
        left = Formatter.for(left_node).new(left_node, @indentation, self).format
        right = Formatter.for(right_node).new(right_node, @indentation, self).format

        if needs_parens?
          "(#{left} #{operator} #{right})"
        else
          "#{left} #{operator} #{right}"
        end
      else
        body, method = node.children
        content = Formatter.for(body).new(body, @indentation, self).format
        "#{content}.#{method}"
      end
    end

    private

    def infix?
      node.children.length == 3
    end

    def needs_parens?
      parent&.type == :or || parent&.type == :and
    end
  end

  class ClassFormatter < BaseFormatter
    def format
      class_details, inherits_from, body = node.children
      _, class_name = class_details.children

      content = Formatter.for(body).new(body, indentation + 2, self).format
      "#{indents}class #{class_name}\n#{content}\n#{indents}end" # TODO handle inheritance
    end
  end

  class CassignFormatter < BaseFormatter
    def format
      _uknown, variable, body = node.children
      content = Formatter.for(body).new(body, indentation + 2, self).format
      "#{indents}#{variable} = #{content}"
    end
  end

  class ArrayFormatter < BaseFormatter
    def format
      elements = node.children.map do |nested_node|
        Formatter.for(nested_node).new(nested_node, indentation + 2, self).format
      end

      "[#{elements.join(", ")}]"
    end
  end

  class BeginFormatter < BaseFormatter
    def format
      body = node.children[0]
      content = Formatter.for(body).new(body, indentation + 2, self).format

      "(#{content})"
    end
  end
end
