module Prettyrb
  module Nodes
    class AndNode < BaseNode
      include LogicalOperatorHelper

      def operator
        "&&"
      end
    end
  end
end
