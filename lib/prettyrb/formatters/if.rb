module Prettyrb
  module Formatters
    class If < Base
      def format
        condition, body = node.children
        start = "#{indents}if "
        condition = Formatter.for(condition).new(condition, @indentation + 2, self).format
        body = Formatter.for(body).new(body, @indentation + 2, self).format
        ending = "#{indents}end"

        "#{start}#{condition}\n#{body}\n#{ending}"
      end
    end
  end
end
