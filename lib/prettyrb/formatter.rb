module Prettyrb
  MAX_LINE_LENGTH = 100

  class Formatter
    def initialize(code)
      @code = code
    end

    def format
      root_node, _comments = Parser::CurrentRuby.parse_with_comments(@code)

      visitor = Visitor.new
      visitor.visit(root_node, nil)

      visitor.output
    end

    private

    def format_type(node, indentation)
      case node.node_type
      when :if
        IfFormatter.new(node, indentation).format
      else
        raise "can't handle #{node}"
      end
    end

    attr_reader :code
  end
end
