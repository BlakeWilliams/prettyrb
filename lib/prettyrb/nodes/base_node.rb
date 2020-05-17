require "delegate"

module Prettyrb
  module Nodes
    class BaseNode < Parser::AST::Node
      def initialize(type, children, properties)
        @mutable = {}

        super

        children&.each do |child|
          next unless child.is_a?(BaseNode)
          child.parent = self
        end

        self
      end

      def parent
        @mutable[:parent]
      end

      def string?
        type == :str || type == :dstr
      end

      protected

      def parent=(parent)
        @mutable[:parent] = parent
      end
    end
  end
end
