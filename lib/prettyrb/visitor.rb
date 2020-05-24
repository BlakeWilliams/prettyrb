module Prettyrb
  class Builder
    attr_reader :parts

    include Enumerable

    def initialize(*args)
      @parts = args
    end

    def each
      @parts.each
    end
  end
  

  class Concat < Builder; end
  class Group < Builder; end
  class Join < Builder; end
  class Indent < Builder; end
  class SplittableGroup < Builder
    attr_reader :prefix, :suffix, :joiner

    def initialize(prefix: nil, suffix: nil, joiner: ",", parts:)
      super(*parts)
      @prefix = prefix
      @suffix = suffix
      @joiner = joiner
    end
  end
  class Hardline < Builder; end
  class Softline < Builder
    attr_reader :fallback

    def initialize(*args, fallback: nil)
      super(args)
      @fallback = fallback
    end
  end

  class Visitor
    MAX_LENGTH = 100
    SINGLE_LINE = "single_line"
    MULTI_LINE = "multi_line"

    FNAMES = [
      "..",
      "|",
      "ˆ",
      "&",
      "<=>",
      "==",
      "===",
      "=˜",
      ">",
      ">=",
      "<",
      "<=",
      "+",
      "-",
      "*",
      "/",
      "%",
      "**",
      "<<",
      ">>",
      "~",
      "+@",
      "-@",
      "[]",
      "[]="
    ]
    VALID_SYMBOLS = FNAMES + ["!", "!="]

    def initialize(root_node)
      @output = ""
      @builder = visit(root_node)
    end

    def output
      Writer.new(@builder).to_s
    end

    def visit(node)
      case node.type
      when :def
        args_blocks = visit node.args if node.args
        body_blocks = visit node.body if node.body

        Join.new(
          Concat.new(
            "def",
            node.name,
          ),
          args_blocks,
          Hardline.new,
          Indent.new(
            body_blocks
          ),
          Hardline.new,
          "end"
        )
      when :args
        if node.children.length > 0
          Group.new(
            "(",
            Softline.new,
            *node.children.map(&method(:visit)),
            Softline.new,
            ")"
          )
        else
          nil
        end
      when :lvasgn
        right_blocks = visit node.children[1] if node.children[1]

        Join.new(
          Concat.new(
            node.children[0].to_s,
            "=",
          ),
          Group.new(
            " ",
            right_blocks,
          )
        )
      when :send
        if node.infix?
        elsif node.negative?
        else
          Join.new(
            visit(node.target),
            ".",
            node.method,
            "(",
            *visit_each(node.arguments),
            ")",
          )
        end
      when :array
        array_nodes = node.children.each_with_object([]) do |child, acc|
          acc.push visit(child)
        end

        Join.new(
          SplittableGroup.new(prefix: "[", suffix: "]", joiner: ",", parts: array_nodes),
        )
      when :str
        Join.new(
          "\"",
          node.format,
          "\"",
        )
      else
        raise "Unexpected node type: #{node.type}"
      end
    end

    def visit_each(node)
      node.map do |child|
        visit(child)
      end
    end
  end
end
