module Prettyrb
  module Formatters
    class Class < Base
      def format
        class_details, inherits_from, body = node.children
        _, class_name = class_details.children

        content = Formatter.for(body).new(body, indentation + 2, self).format
        "#{indents}class #{class_name}\n#{content}\n#{indents}end" # TODO handle inheritance
      end
    end
  end
end
