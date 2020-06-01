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

      def self_target?
        children[2].nil? && method.to_s.end_with?("@")
      end

      def infix?
        !children[1].to_s.match?(/^[a-zA-Z_]/)
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

      def left_hand_mass_assignment?
        parent&.type == :mlhs && method.to_s.end_with?("=")
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

      def heredoc_target
        child_target = target

        while child_target
          return child_target if child_target.is_a?(StrNode) || child_target.is_a?(DstrNode)
          child_target = child_target.target
        end

        nil
      end

      def heredoc_arguments?
        heredoc_arguments.any?
      end

      def heredoc_arguments
        arguments.each_with_object([]) do |child, args|
          if child.string? && child.heredoc?
            args << child
          elsif child.type == :send && child.called_on_heredoc?
            args << child.heredoc_target
          end
        end
      end
    end
  end
end
