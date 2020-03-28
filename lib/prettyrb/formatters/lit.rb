module Prettyrb
  module Formatters
    class Lit < Base
      def format
        node.children[0]
      end
    end
  end
end
