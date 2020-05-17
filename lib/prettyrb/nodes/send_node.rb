module Prettyrb
  module Nodes
    class SendNode < BaseNode
      def target
        children[0]
      end

      def method
        children[1]
      end

      def arguments
        children[2..-1]
      end

      def infix?
        !children[1].to_s.match?(/^[a-zA-Z]/)
      end

      def negative?
        children[1] == :-@ && children[2].nil?
      end

      def negate?
        children[1] == :!
      end

      def array_assignment?
        children[1] == :[]=
      end

      def array_access?
        children[1] == :[]
      end

      def called_on_heredoc?
        child = target

        while child&.type == :send || child&.string?
          return true if child.string? && child.heredoc?
          child = child.children[0]
          return false unless child.respond_to?(:type)
        end

        false
      end

      def heredoc_arguments?
        arguments.any? do |child|
          child.string? && child.heredoc? || (child.type == :send && child.called_on_heredoc?)
        end
      end
    end
  end
end
