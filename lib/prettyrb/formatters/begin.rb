module Prettyrb
  module Formatters
    class Begin < Base
      def in_conditions?
        true
      end

      def format
        body = node.children[0]
        content = Formatter.for(body).new(body, indentation + 2, self).format

        "(#{content})"
      end

      def indents
        if over_line_length?
          super
        else
          ''
        end
      end

      def over_line_length?
        false
      end
    end
  end
end
