module Prettyrb
  module Nodes
    class DstrNode < BaseNode
      include StringHelper

      HEREDOC_TYPE_REGEX = /<<(.)?/

      def includes_escapes?
        loc.expression.source[1...-1].include?("\\")
      end

      def is_single_quoted?
        loc.expression.source[1] == "'"
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
