module Prettyrb
  module Formatters
    class Base
      attr_reader :node, :parent

      def initialize(node, indentation, parent)
        @node = node
        @indentation = indentation
        @parent = parent
        @skip_indentation_unless_multiline = false
      end

      def type
        node.type
      end

      def indents(extra = 0)
        ' ' * (indentation + extra)
      end

      def indentation
        return 0 if skip_indentation_unless_multiline?
        @indentation
      end

      def skip_indentation_unless_multiline?
        @skip_indentation_unless_multiline
      end

      def skip_indentation_unless_multiline
        @skip_indentation_unless_multiline = false
        self
      end

      # Helper method to make formatters less awful to use inside of other formatters
      def subformatter(node, indents: nil)
        indents ||= indentation + 2
        Formatter.for(node).new(node, indents, self)
      end
    end
  end
end
