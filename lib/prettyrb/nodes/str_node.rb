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

      def send_argument?
        node_parent = parent

        while node_parent
          return true if parent.type == :send && parent.to_a.index(self) > 1
          node_parent = node_parent.parent
        end

        false
      end
    end
  end
end
