module Prettyrb
  module Formatters
    class Base
      attr_reader :node, :indentation, :parent

      def initialize(node, indentation, parent)
        @node = node
        @indentation = indentation
        @parent = parent
      end

      def type
        node.type
      end

      def indents
        ' ' * indentation
      end
    end
  end
end
