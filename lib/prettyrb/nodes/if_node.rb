module Prettyrb
  module Nodes
    class IfNode < BaseNode
      def if_type
        if is_elsif?
          "elsif"
        elsif unless_node?
          "unless"
        else
          "if"
        end
      end

      def conditions_node
        children[0]
      end

      def body_node
        if unless_node?
          children[2]
        else
          children[1]
        end
      end

      def else_body_node
        if unless_node?
          children[1]
        else
          children[2]
        end
      end

      def has_elsif?
        else_body_node&.type == :if && children[1]&.type != :if
      end

      def is_elsif?
        parent&.type == :if && parent&.children[1]&.type != :if
      end

      def unless_node?
        children[1].nil? && children[2] != :if
      end
    end
  end
end
