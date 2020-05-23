module Prettyrb
  module Correcter
    class Conditions < Base
      def initialize(*args)
        super
        @is_multiline = false
        @current_line_length = output.length
      end

      def perform
        if node.parent&.type == :begin
          write "("
        end

        if multiline_conditional_level > 0
          visit node.left
          write " #{node.operator}"
          newline
          visit node.right
        else
          inline = capture do
            visit node.left
            write " #{node.operator} "
            visit node.right
          end

          if inline.length + @current_line_length > Prettyrb::Visitor::MAX_LENGTH
            in_multiline_conditional do
              visit node.left
              write " #{node.operator}"
              newline
              visit node.right
            end
          else
            write inline
          end
        end

        if node.parent&.type == :begin
          write ")"
        end
      end

      def multiline?
        return @is_multiline if defined?(@is_multiline)

        content = capture do
        end
      end

      def write_multiline_conditional(node)
        visit node.children[0]

        if node.type == :or
          write " ||"
        elsif node.type == :and
          write " &&"
        end

        newline

        visit node.children[1]
      end

    end
  end
end
