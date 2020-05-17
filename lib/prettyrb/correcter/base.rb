module Prettyrb
  module Correcter
    class Base
      extend Forwardable

      def_delegators :visitor, :write, :newline, :visit, :capture, :current_line, :indent

      def initialize(node:, visitor:)
        @node = node
        @visitor = visitor
      end

      protected

      attr_reader :node, :visitor
    end
  end
end
