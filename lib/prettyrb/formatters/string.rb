module Prettyrb
  module Formatters
    class String < Base
      def format
        if parent.type == :array
          "\"#{node.children[0]}\""
        else
          "#{indents}\"#{node.children[0]}\""
        end
      end
    end
  end
end
