module Prettyrb
  MAX_LINE_LENGTH = 100

  class Formatter
    def initialize(code)
      @code = code
    end

    def format
      parser = Parser::CurrentRuby.new(Prettyrb::Builder.new)

      parser.diagnostics.all_errors_are_fatal = true
      parser.diagnostics.ignore_warnings      = true

      parser.diagnostics.consumer = lambda do |diagnostic|
        $stderr.puts(diagnostic.render)
      end

      root_node, _comments = parser.parse_with_comments(
        Parser::CurrentRuby.send(:setup_source_buffer, "file='(string)'", 1, @code, parser.default_encoding)
      )

      visitor = Visitor.new(root_node)
      visitor.visit(root_node)

      visitor.output
    end

    private

    attr_reader :code
  end
end
