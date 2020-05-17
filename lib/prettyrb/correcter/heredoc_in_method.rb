module Prettyrb
  module Correcter
    class HeredocInMethod < Base

      def initialize(node:, visitor:)
        super
        @heredocs = []
      end

      def perform
        visit node.target if node.target
        write "." if node.target
        write node.method.to_s
        write "("

        args = capture do
          write_arguments
        end

        if current_line.length + args.length > Prettyrb::Visitor::MAX_LENGTH
          @heredocs = []

          indent do
            newline
            write_arguments(multiline: true)
          end
        else
          write args
        end

        write ")"

        @heredocs.each do |heredoc_node|
          newline
          write heredoc_node.heredoc_body, skip_indent: true

          write heredoc_node.heredoc_identifier
        end
      end

      private

      def write_arguments(multiline: false)
        node.arguments.each_with_index do |arg_node, index|
          if arg_node.string? && arg_node.heredoc?
            @heredocs.push(arg_node)
            write "<<"
            write arg_node.heredoc_type if arg_node.heredoc_type
            write arg_node.heredoc_identifier
          elsif arg_node.type == :send && arg_node.called_on_heredoc?
            current_node = arg_node.target
            while !current_node.string?
              current_node = current_node.target
            end

            @heredocs.push(current_node)
            HeredocMethodChain.new(node: current_node, visitor: visitor).perform
          else
            visit arg_node
          end

          if multiline
            write ","
            newline
          elsif node.arguments.length - 1 != index
            write ", "
          end
        end
      end
    end
  end
end
