module Prettyrb
  module Nodes
    class OrNode < BaseNode
      include LogicalOperatorHelper

      def operator
        "||"
      end
    end
  end
end
