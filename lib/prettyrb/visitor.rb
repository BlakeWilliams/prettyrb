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
  class Join < Builder
    attr_reader :separator

    def initialize(separator: ",", parts:)
      if parts.is_a?(Array)
        super(*parts)
      else
        super(parts)
      end
      @separator = separator
    end
  end
  class IfBreak
    attr_reader :without_break, :with_break
    def initialize(without_break:, with_break: )
      @without_break = without_break
      @without_break = with_break
    end
  end
  class Indent < Builder; end
  class Hardline < Builder
    attr_reader :count
    def initialize(count: 1)
      @count = count
    end
  end
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
      when :sclass
        body = if node.children[1]
          Concat.new(
            Indent.new(
              Hardline.new,
              visit(node.children[1]),
            ),
            Hardline.new,
          )
        else
          Hardline.new
        end

        Concat.new(
          "class << ",
          visit(node.children[0]),
          body,
          "end"
        )
      when :class
        inheritance = if node.children[1]
          Concat.new(
            " < ",
            visit(node.children[1]),
          )
        end

        Concat.new(
          "class ",
          visit(node.children[0]),
          *inheritance,
          Indent.new(
            Hardline.new,
            visit(node.children[2]),
          ),
          Hardline.new,
          "end"
        )
      when :if
        branches = node.branches.each_with_index.map do |branch, index|
          is_last = index == node.branches.length - 1
          if index == 0
            possible_newline = Hardline.new if !is_last

            Concat.new(
              Indent.new(
                Hardline.new,
                visit(branch),
              ),
              possible_newline,
            )
          elsif is_last
            Concat.new(
              "else",
              Indent.new(
                Hardline.new,
                visit(branch),
              )
            )
          end
        end.compact

        Concat.new(
          "if ",
          visit(node.conditions),
          *branches,
          Hardline.new,
          "end"
        )
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
            " ||",
            IfBreak.new(with_break: "", without_break: " "),
            Softline.new,
            visit(node.children[1]),
          )
        )
      when :and
        builder = Concat.new(
          visit(node.children[0]),
          " &&",
          IfBreak.new(with_break: "", without_break: " "),
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
          Concat.new(
            "(",
            *visit_each(node.children), # TODO Split or softline?
            ")"
          )
        else
          children = []
          node.children.each_with_index do |child, index|
            children << visit(child)

            next_child = node.children[index + 1]

            if next_child&.type != child.type && node.children.last != child
              children << Hardline.new(count: 2)
            elsif node.children.last != child
              children << Hardline.new
            end
          end

          Concat.new(*children)
        end
      when :defs
        puts node.inspect
        args_blocks = visit node.children[2] if node.children[2]

        body = if node.children[3]
          Concat.new(
            Indent.new(
              Hardline.new,
              visit(node.children[3]),
            ),
            Hardline.new,
          )
        else
          Hardline.new
        end

        Concat.new(
          "def ",
          visit(node.children[0]),
          ".",
          node.children[1],
          args_blocks,
          body,
          "end"
        )
      when :def
        args_blocks = visit node.args if node.args
        body_blocks = visit node.body if node.body

        body = if node.body
          Concat.new(
            Indent.new(
              Hardline.new,
              body_blocks,
            ),
            Hardline.new,
          )
        else
          Hardline.new
        end

        Group.new(
          Concat.new(
            "def ",
            # TODO possible break
            node.name,
          ),
          args_blocks,
          body,
          "end"
        )
      when :args
        if node.children.length > 0
          Group.new(
            "(",
            Softline.new,
            Join.new(
              separator: ",",
              parts: node.children.map(&method(:visit)),
            ),
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

        # TODO test softline grouping on right side of `=`
        Group.new(
          node.children[1],
          " = ",
          # IfBreak.new(with_break: "", without_break: " "),
          # Softline.new,
          visit(node.children[2]),
        )
      when :lvasgn
        right_blocks = visit node.children[1] if node.children[1]

        Concat.new(
          node.children[0].to_s,
          " = ",
          # TODO line break for long lines
          right_blocks,
        )
      when :send
        if node.infix?
          Group.new(
            Concat.new(
              visit(node.target),
              " ",
              node.method,
              " ",
              visit(node.children[2]), # TODO name?
            )
          )
        elsif node.negative?
          raise "handle negative :send"
        elsif node.self_target?
          Join.new(
            node.method.to_s[0..-2],
            visit(node.target),
          )
        else
          arguments = if node.arguments.length > 0
            Concat.new(
              "(",
              Join.new(separator: ",", parts: visit_each(node.arguments)),
              ")",
            )
          end

          if node.target
            Concat.new(
              visit(node.target),
              ".",
              node.method,
              arguments,
            )
          else
            Concat.new(
              node.method,
              arguments,
            )
          end
        end
      when :array
        array_nodes = node.children.each_with_object([]) do |child, acc|
          acc.push Concat.new(Softline.new, visit(child))
        end

        Group.new(
          "[",
          Indent.new(
            Join.new(separator: ",", parts: array_nodes),
          ),
          Softline.new,
          "]"
        )
      when :str
        Concat.new(
          "\"",
          node.format,
          "\"",
        )
      when :alias
        Concat.new(
          "alias ",
          visit(node.children[0]),
          " ",
          visit(node.children[1]),
        )
      when :sym
        content = node.children[0].to_s

        # TODO handle already quoted symbols
        if !VALID_SYMBOLS.include?(content) && !content.match?(/\A[a-zA-Z_]{1}[a-zA-Z0-9_!?=]*\z/)
          Concat.new(
            ":",
            "'",
            content,
            "'",
          )
        else
          if node.parent&.type == :pair && node.parent.children[0] == node
            Concat.new(
              content,
              ": ",
            )
          else
            Concat.new(
              ":",
              content,
            )
          end
        end
      when :undef
        Concat.new(
          "undef",
          " ",
          Join.new(separator: ",", parts: visit_each(node.children))
        )
      when :forward_args
        "(...)"
      when :forwarded_args
        "..."
      when :optarg
        Concat.new(
          node.children[0],
          " = ",
          visit(node.children[1]),
        )
      when :restarg
        Concat.new(
          "*",
          node.children[0],
        )
      when :kwarg
        Concat.new(
          node.children[0],
          ":",
        )
      when :kwoptarg
        Concat.new(
          node.children[0],
          ": ",
          visit(node.children[1]),
        )
      when :kwrestarg
        if node.children[0]
          "**" + node.children[0].to_s
        else
          "**"
        end
      when :kwnilarg
        "**nil"
      when :lvar
        node.children[0].to_s
      when :true, :false, :nil, :self
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
