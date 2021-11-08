module Prettyrb
  module Nodes
    class StrNode < BaseNode
      include StringHelper

      STRING_WRAPPERS = ["'", '"'].freeze

      def includes_escapes?
        loc.expression.source[1...-1].inspect.include?("\\") # super hacky, but whatever
      end

      def is_single_quoted?
        loc.expression.source[0] == "'"
      end

      def is_single_char?
        loc.expression.source[0] == "?"
      end

      def content
        raw_content = loc.expression.source
        if STRING_WRAPPERS.include?(raw_content[0])
          raw_content[1...-1]
        else
          raw_content
        end
      end

      def format
        raw_content = loc.expression.source

        content = if STRING_WRAPPERS.include?(raw_content[0])
          raw_content[1...-1]
        else
          raw_content
        end

        if raw_content[0] == "'"
          content.gsub('"', '\\"').gsub('#{', '\\#{')
        else
          content.gsub("\\", "\\\\")
        end
      end
    end
  end
end
