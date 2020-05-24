module Prettyrb
  module Nodes
    class DefNode < BaseNode
      def name
        children[0]
      end

      def args
        children[1]
      end

      def body
        children[2]
      end
    end
  end
end
