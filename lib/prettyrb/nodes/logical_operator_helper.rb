module Prettyrb
  module Nodes
    module LogicalOperatorHelper
      def left
        children[0]
      end

      def right
        children[1]
      end
    end
  end
end
