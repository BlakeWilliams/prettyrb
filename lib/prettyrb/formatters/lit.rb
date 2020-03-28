module Prettyrb
  module Formatters
    class Lit < Base
      def format
        "#{indents}#{node.children[0]}"
      end

      def indents
        if parent&.type == :if || parent&.type == :and || parent&.type == :or
          ""
        else
          super
        end
      end
    end
  end
end
