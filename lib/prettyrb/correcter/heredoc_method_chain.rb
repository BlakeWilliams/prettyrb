module Prettyrb
  module Correcter
    class HeredocMethodChain < Base
      def initialize(node:, visitor:)
        @node = node
        @visitor = visitor
      end

      def perform
        write "<<"
        write node.heredoc_type if node.heredoc_type
        write node.heredoc_identifier

        # if methods are called on the heredoc
        previous_parent = nil
        parent = node.parent
        while parent&.type == :send && parent.called_on_heredoc?
          write "."
          write parent.children[1].to_s
          if parent.arguments.length > 0
            write "("

            parent.arguments.each_with_index do |child_node, index|
              next if child_node == node || child_node == previous_parent
              visit child_node
              write ", " if parent.children[2..-1].length - 1 != index
            end

            write ")"
          end

          previous_parent = parent
          parent = parent&.parent
        end
      end

      private

      attr_reader :node, :visitor

    end
  end
end
