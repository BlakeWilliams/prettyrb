require "ruby_parser"
require "prettyrb/version"

module Prettyrb
  class Error < StandardError; end

  class Formatter
    def self.for(sexp)
      case sexp.sexp_type
      when :if
        IfFormatter
      when :str
        StringFormatter
      when :or
        OrFormatter
      when :and
        AndFormatter
      when :lit
        LitFormatter
      when :call
        CallFormatter
      when :class
        ClassFormatter
      when :cdecl
        CdeclFormatter
      when :array
        ArrayFormatter
      else
        raise "can't handle #{sexp}"
      end
    end

    def initialize(code)
      @code = code
    end

    def format
      sexp_tree = RubyParser.new.parse(@code)

      self.class.for(sexp_tree).new(sexp_tree, 0, nil).format
    end

    private

    def format_type(sexp, indentation)
      case sexp.sexp_type
      when :if
        IfFormatter.new(sexp, indentation).format
      else
        raise "can't handle #{sexp}"
      end
    end

    attr_reader :code
  end

  class BaseFormatter
    attr_reader :sexp, :indentation, :parent

    def initialize(sexp, indentation, parent)
      @sexp = sexp
      @indentation = indentation
      @parent = parent
    end

    def type
      sexp.sexp_type
    end

    def indents
      ' ' * indentation
    end
  end

  class LitFormatter < BaseFormatter
    def format
      sexp[1]
    end
  end

  class StringFormatter < BaseFormatter
    def format
      if parent.type == :array
        "\"#{sexp[1]}\""
      else
        "#{indents}\"#{sexp[1]}\""
      end
    end
  end

  class IfFormatter < BaseFormatter
    def format
      start = "#{' ' * @indentation}if "
      condition = Formatter.for(sexp[1]).new(@sexp[1], @indentation + 2, self).format
      body = Formatter.for(sexp[2]).new(@sexp[2], @indentation + 2, self).format
      ending = "#{' ' * @indentation}end"

      "#{start}#{condition}\n#{body}\n#{ending}"
    end
  end

  class OrFormatter < BaseFormatter
    def format
      left = Formatter.for(sexp[1]).new(sexp[1], @indentation, self).format
      right = Formatter.for(sexp[2]).new(sexp[2], @indentation, self).format

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
      left = Formatter.for(sexp[1]).new(sexp[1], @indentation, self).format
      right = Formatter.for(sexp[2]).new(sexp[2], @indentation, self).format

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
        left = Formatter.for(sexp[1]).new(sexp[1], @indentation, self).format
        right = Formatter.for(sexp[3]).new(sexp[3], @indentation, self).format

        if needs_parens?
          "(#{left} #{sexp[2]} #{right})"
        else
          "#{left} #{sexp[2]} #{right}"
        end
      else
        content = Formatter.for(sexp[1]).new(sexp[1], @indentation, self).format
        "#{content}.#{sexp[2]}"
      end
    end

    private

    def infix?
      sexp.length == 4
      # !sexp[1].nil? # If the first argument is present, this is an infix call
    end

    def needs_parens?
      parent&.type == :or || parent&.type == :and
    end
  end

  class ClassFormatter < BaseFormatter
    def format
      content = Formatter.for(sexp[3]).new(sexp[3], indentation + 2, self).format
      "#{indents}class #{sexp[1]}\n#{content}\n#{indents}end" # TODO handle inheritance
    end
  end

  class CdeclFormatter < BaseFormatter
    def format
      content = Formatter.for(sexp[2]).new(sexp[2], indentation + 2, self).format
      "#{indents}#{sexp[1]} = #{content}"
    end
  end

  class ArrayFormatter < BaseFormatter
    def format
      elements = sexp[1..-1].map do |nested_sexp|
        Formatter.for(nested_sexp).new(nested_sexp, indentation + 2, self).format
      end

      "[#{elements.join(", ")}]"
    end
  end
end
