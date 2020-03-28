module Prettyrb
  module Formatters
    class Array < Base
      def format
        elements = node.children.map do |nested_node|
          Formatter.for(nested_node).new(nested_node, indentation + 2, self).format
        end

        "[#{elements.join(", ")}]"
      end
    end
  end
end
