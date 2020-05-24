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

    def inspect
      inspect_children(self, indent_level: 0)
    end

    private

    def inspect_children(builder, indent_level:)
      if builder.respond_to?(:parts)
        children = builder.parts.map do |p|
          inspect_children(p, indent_level: indent_level + 1)
        end.join("\n")

        "  " * indent_level + "(#{builder.class}\n#{children})"
      else
        "  " * indent_level + builder.inspect
      end
    end
  end
  

  class Concat < Builder; end
  class Group < Builder
    attr_reader :joiner

    def initialize(*args, joiner: "")
      super(*args)
      @joiner = joiner
    end
  end
  # TODO MAYBE
  # introduce MultilineGroup for cases when we know each individual top-level item should
  # be on its own line. cases: `begin` outside of a conditional, kwbegin, class
  # body, method body, conditional bodies
  class MultilineJoin < Builder; end
  class Join < Builder; end
  class Indent < Builder; end
  class SplittableGroup < Builder
    attr_reader :prefix, :suffix, :joiner

    def initialize(prefix: nil, suffix: nil, joiner: ",", parts:)
      if parts.is_a?(Array)
        super(*parts)
      else
        super(parts)
      end
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
      when :class
        inheritance = if node.children[1]
          Concat.new(
            "<",
            visit(node.children[1]),
          )
        end

        Join.new(
          Concat.new(
            "class",
            visit(node.children[0]),
            *inheritance,
          ),
          Hardline.new,
          Indent.new(
            MultilineJoin.new(
              visit(node.children[2]),
            )
          ),
          Hardline.new,
          "end"
        )
      when :if
        branches = node.branches.each_with_index.map do |branch, index|
          is_last = index == node.branches.length - 1
          if index == 0
            possible_newline = Hardline.new if !is_last

            Join.new(
              Indent.new(
                MultilineJoin.new(
                  visit(branch),
                  possible_newline,
                )
              )
            )
          elsif is_last
            Join.new(
              "else",
              Hardline.new,
              Indent.new(
                MultilineJoin.new(
                  visit(branch),
                )
              ),
            )
          end
        end.compact

        Join.new(
          Concat.new(
            "if",
            visit(node.conditions),
          ),
          Hardline.new,
          *branches,
          Hardline.new,
          "end"
        )
        # branches = node.branches.each_with_object([]) do |branch, acc|
        # end
        # branches = Join.new(*branches)
        #
        # Group.new(
        #   "if",
        #   SplittableGroup.new(prefix: "(", suffix: ")", joiner: ",", parts: visit(node.conditions)),
        #   Hardline,
        #   "end",
        # )
      when :const
        prefix = if node.children[0]
          visit node.children[0]
        end

        Concat.new(
          prefix,
          node.children[1],
        )
      when :or
        Group.new(
          Concat.new(
            visit(node.children[0]),
            "||",
            Softline.new,
            visit(node.children[1]),
          )
        )
      when :and
        builder = Concat.new(
          visit(node.children[0]),
          "&&",
          Softline.new,
          visit(node.children[1]),
        )

        if node.parent&.type == :and || node.parent&.type == :or
          builder
        else
          Group.new(
            Indent.new(
              builder
            )
          )
        end
      when :int
        node.children[0].to_s
      when :begin
        in_conditional = node.parent&.type == :if || node.parent&.type == :or || node.parent&.type == :and

        if in_conditional
          Join.new(
            "(",
            *visit_each(node.children),
            ")"
          )
        else
          raise
        end
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
            MultilineJoin.new(
              body_blocks
            )
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
      when :casgn
        if !node.children[0].nil?
          puts "FATAL: FIX CASGN FIRST ARGUMENT"
          exit 1
        end

        Join.new(
          Concat.new(
            node.children[1],
            "=",
            visit(node.children[2]),
          )
        )
      when :lvasgn
        right_blocks = visit node.children[1] if node.children[1]

        Join.new(
          Concat.new(
            node.children[0].to_s,
            "=",
            right_blocks,
          ),
        )
      when :send
        if node.infix?
          Group.new(
            Concat.new(
              visit(node.target),
              node.method,
              visit(node.children[2]), # TODO name?
            )
          )
        elsif node.negative?
        else
          arguments = if node.arguments.length > 0
            SplittableGroup.new(prefix: "(", suffix: ")", joiner: ",", parts: visit_each(node.arguments))
          end

          Join.new(
            visit(node.target),
            ".",
            node.method,
            arguments,
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
      when :true, :false, :nil
        node.type.to_s
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
