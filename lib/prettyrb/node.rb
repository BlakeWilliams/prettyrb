require "delegate"

module Prettyrb
  class Node < Parser::AST::Node
    def initialize(type, children, properties)
      @mutable = {}

      super

      children.each do |child|
        next unless child.is_a?(Node)
        child.parent = self
      end

      self
    end

    def parent
      @mutable[:parent]
    end

    protected

    def parent=(parent)
      @mutable[:parent] = parent
    end
  end
end
