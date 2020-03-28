module Prettyrb
  module Formatters
    class Cassign < Base
      def format
        _uknown, variable, body = node.children
        content = Formatter.for(body).new(body, indentation + 2, self).format
        "#{indents}#{variable} = #{content}"
      end
    end
  end
end
