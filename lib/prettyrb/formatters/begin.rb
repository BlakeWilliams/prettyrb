module Prettyrb
  module Formatters
    class Begin < Base
      def format
        body = node.children[0]
        content = Formatter.for(body).new(body, indentation + 2, self).format

        "(#{content})"
      end
    end
  end
end
