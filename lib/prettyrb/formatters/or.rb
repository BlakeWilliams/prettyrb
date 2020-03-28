module Prettyrb
  module Formatters
    class Or < Base
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
  end
end
