module Prettyrb
  module Correcter
    class BasicConditional < Base
      def perform
        write node.if_type

        write " "
        indent do
          write conditions
        end

        newline

        indent do
          visit node.body_node
        end

        newline

        if node.else_body_node
          if node.has_elsif?
            visit node.else_body_node
          else
            write "else"
            newline

            indent do
              visit node.else_body_node
            end

            newline
          end
        end

        if !node.is_elsif?
          write "end"
        end
      end

      private

      def conditions
        capture do
          visit node.conditions_node
        end
      end
    end
  end
end
