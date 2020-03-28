module Prettyrb
  class Formatter
    def self.for(node)
      case node.type
      when :if
        Formatters::If
      when :str
        Formatters::String
      when :or
        Formatters::Or
      when :and
        Formatters::And
      when :int
        Formatters::Lit
      when :send
        Formatters::Call
      when :class
        Formatters::Class
      when :casgn
        Formatters::Cassign
      when :array
        Formatters::Array
      when :begin
        Formatters::Begin
      when :false
        Formatters::False
      when :true
        Formatters::True
      else
        raise "can't handle #{node.inspect}"
      end
    end

    def initialize(code)
      @code = code
    end

    def format
      root_node, comments = Parser::CurrentRuby.parse_with_comments(@code)

      self.class.for(root_node).new(root_node, 0, nil).format
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
