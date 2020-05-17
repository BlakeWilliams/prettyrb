module Prettyrb
  module Nodes
    class RegexpNode < BaseNode
      include StringHelper

      def percent?
        loc.expression.source.start_with?("%")
      end

      def percent_type
        loc.expression.source[1]
      end

      def start_delimiter
        loc.expression.source[2]
      end

      def end_delimiter
        loc.expression.source[-1]
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
