module Prettyrb
  module Nodes
    class StrNode < BaseNode
      include StringHelper

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
