module Prettyrb
  module Formatters
    class Call < Base
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
  end
end
