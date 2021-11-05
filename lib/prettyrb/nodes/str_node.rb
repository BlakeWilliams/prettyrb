module Prettyrb
  module Nodes
    class StrNode < BaseNode
      include StringHelper

      def includes_escapes?
        loc.expression.source[1...-1].inspect.include?("\\") # super hacky, but whatever
      end

      def is_single_quoted?
        loc.expression.source[0] == "'"
      end

      def content
        raw_content = loc.expression.source
        content = raw_content[1...-1]
      end

      def format
        raw_content = loc.expression.source
        content = raw_content[1...-1]

        if raw_content[0] == "'"
          content.gsub('"', '\\"').gsub('#{', '\\#{')
        else
          content.gsub("\\", "\\\\")
        end
      end
    end
  end
end
