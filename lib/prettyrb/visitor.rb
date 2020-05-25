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
      @with_break = with_break
    end
  end
  class Indent < Builder; end
  class Dedent < Builder; end
  class Hardline < Builder
    attr_reader :count, :skip_indent
    def initialize(count: 1, skip_indent: false)
      @count = count
      @skip_indent = skip_indent
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
          inheritance,
          Indent.new(
            Hardline.new,
            visit(node.children[2]),
          ),
          Hardline.new,
          "end"
        )
      when :if
        body = if node.body_node
          Concat.new(
            Indent.new(
              Hardline.new,
              visit(node.body_node),
            ),
          )
        else
          Hardline.new
        end

        elsifs = if node.has_elsif?
          [Hardline.new] + node.elsif_branches.map do |elsif_branch|
            Concat.new(
              "elsif ",
              visit(elsif_branch.conditions),
              Indent.new(
                Hardline.new,
                visit(elsif_branch.body_node)
              ),
              Hardline.new,
            )
          end
        end

        else_content = if node.else_branch
          starting_newline = if !node.has_elsif?
            Hardline.new
          end
          Concat.new(
            starting_newline,
            "else",
            Indent.new(
              Hardline.new,
              visit(node.else_branch)
            ),
            Hardline.new,
          )
        else
          Hardline.new
        end

        Concat.new(
          node.unless_node? ? "unless" : "if",
          " ",
          visit(node.conditions),
          body,
          *elsifs,
          else_content,
          "end"
        )
      when :case
        arguments = if node.children[0]
          Concat.new(
            " ",
            visit(node.children[0])
          )
        end

        cases = node.children[1..-1].map do |child|
          if child && child.type != :when
            Concat.new(
              "else",
              Ident.new(
                Hardline.new,
                visit(child)
              ),
            )
            visit child
          elsif child
            visit child
          end
        end

        Concat.new(
          "case",
          arguments,
          Hardline.new,
          Concat.new(*cases),
          Hardline.new,
          "end"
        )
      when :when
        arguments = node.children[0..-2].compact
        body = if node.children.last
          Indent.new(
            Hardline.new,
            visit(node.children.last)
          )
        end

        arguments = if arguments.size > 0
          Join.new(separator: ",", parts: visit_each(arguments))
        end

        Concat.new(
          "when",
          Group.new(
            IfBreak.new(with_break: "", without_break: " "),
            Indent.new(
              Softline.new,
              arguments,
            ),
          ),
          body
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
        in_conditional = (node.parent&.type == :if && node.parent.children[0] == node) ||
          node.parent&.type == :or ||
          node.parent&.type == :and

        if in_conditional && node.type == :begin
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
      when :masgn
        Concat.new(
          visit(node.children[0]),
          " = ",
          visit(node.children[-1])
        )
      when :mlhs
        if node.parent&.type == :mlhs
          Concat.new(
            "(",
            Join.new(separator: ",", parts: visit_each(node.children)),
            ")"
          )
        else
          Join.new(separator: ",", parts: visit_each(node.children))
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
      when :lvasgn, :cvasgn, :ivasgn
        right_blocks = visit node.children[1] if node.children[1]

        if right_blocks
          Concat.new(
            node.children[0].to_s,
            " = ",
            # TODO line break for long lines
            right_blocks,
          )
        else
          Concat.new(
            node.children[0].to_s,
          )
        end
      when :send
        if node.called_on_heredoc?
          visit node.target
        elsif node.array_assignment?
          equals = if !node.left_hand_mass_assignment?
            " = "
          end

          body = if node.children[3]
            visit(node.children[3])
          end

          Concat.new(
            visit(node.target),
            "[",
            visit(node.children[2]),
            "]", # TODO line split
            equals,
            body,
          )
        elsif node.array_access?
          Concat.new(
            visit(node.target),
            "[",
            visit(node.children[2]),
            "]"
          )
        elsif node.negate?
          Concat.new(
            "!",
            visit(node.target),
          )
        elsif node.negative?
          Concat.new(
            "-",
            visit(node.target),
          )
        elsif node.self_target?
          body = visit(node.target) if node.target

          Concat.new(
            node.method.to_s[0..-2],
            body,
          )
        elsif node.infix?
          body = visit(node.children[2]) if node.children[2]

          Group.new(
            Concat.new(
              visit(node.target),
              " ",
              node.method,
              " ",
              body,
            )
          )
        else
          arguments = if node.arguments.length > 0
            Concat.new(
              "(",
              Indent.new(
                Softline.new,
                Join.new(separator: ",", parts: visit_each(node.arguments)),
              ),
              Softline.new,
              ")",
            )
          end

          method = if node.left_hand_mass_assignment?
            node.method.to_s[0...-1]
          else
            node.method
          end

          if node.target
            Concat.new(
              visit(node.target),
              ".",
              method,
              Group.new(
                arguments,
              )
            )
          else
            Concat.new(
              method,
              Group.new(
                arguments,
              )
            )
          end
        end
      when :hash
        if node.children.length > 0
          Group.new(
            "{",
            IfBreak.new(without_break: " ", with_break: ""),
            Indent.new(
              Softline.new,
              Join.new(separator: ",", parts: visit_each(node.children)),
              IfBreak.new(without_break: " ", with_break: ""),
            ),
            Softline.new,
            "}"
          )
        else
          "{}"
        end
      when :pair
        if node.children[0].type == :sym
          Concat.new(
            visit(node.children[0]),
            visit(node.children[1])
          )
        else
          Concat.new(
            visit(node.children[0]),
            " => ",
            visit(node.children[1])
          )
        end
      when :defined?
        Concat.new(
          "defined?(",
          visit(node.children[0]),
          ")"
        )
      when :and_asgn, :or_asgn
        operator = if node.type == :and_asgn
          "&&="
        elsif node.type == :or_asgn
          "||="
        end

        Group.new(
          visit(node.children[0]),
          " ",
          operator,
          IfBreak.new(with_break: "", without_break: " "),
          Softline.new,
          visit(node.children[1])
        )
      when :array
        if node.parent&.type == :resbody
          Join.new(separator: ",", parts: visit_each(node.children))
        elsif node.children[0]&.type == :splat
          visit node.children[0]
        else
          array_nodes = node.children.each_with_object([]) do |child, acc|
            acc.push visit(child)
          end

          Group.new(
            "[",
            Indent.new(
              Softline.new,
              Join.new(separator: ",", parts: array_nodes),
            ),
            Softline.new,
            "]"
          )
        end
      when :regopt
        node.children.map(&:to_s).join("")
      when :regexp
        content = node.children[0...-1].map do |child|
          if child.type == :str
            child.children[0].to_s
          else
            visit child
          end
        end

        options = if node.children[-1]
          visit node.children[-1]
        end

        if node.percent?
          Concat.new(
            "%",
            node.percent_type,
            node.start_delimiter,
            *content,
            node.end_delimiter,
            options,
          )
        else
          Concat.new(
            "/",
            *content,
            "/",
            options,
          )
        end
      when :str
        if node.heredoc?
          method_calls = if node.parent&.type == :send
            method_calls = []
            parent = node.parent

            while parent && parent.type == :send && parent.called_on_heredoc?
              arguments = if parent.arguments.length > 0
                Concat.new(
                  "(",
                  Join.new(separator: ",", parts: visit_each(parent.arguments)),
                  ")",
                )
              end

              method_calls.push(
                Concat.new(
                  ".",
                  parent.children[1].to_s,
                  arguments,
                )
              )
              parent = parent.parent
            end

            Concat.new(*method_calls)
          end

          Concat.new(
            "<<",
            node.heredoc_type,
            node.heredoc_identifier,
            method_calls,
            Hardline.new(skip_indent: true),
            node.heredoc_body,
            node.heredoc_identifier
          )
        elsif node.percent_string?
          body = node.children.map do |child|
            if child.is_a?(String)
              child
            elsif child.type == :str
              child.children[0]
            else
              visit child
            end
          end

          Concat.new(
            "%",
            node.percent_character,
            node.start_delimiter,
            *body,
            node.closing_delimiter,
          )
        else
          Concat.new(
            "\"",
            node.format,
            "\"",
          )
        end
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
      when :kwsplat
        Concat.new(
          "**",
          visit(node.children[0])
        )
      when :splat
        Concat.new(
          "*",
          visit(node.children[0])
        )
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
      when :lvar, :cvar, :ivar
        node.children[0].to_s
      when :true, :false, :nil, :self, :break
        node.type.to_s
      when :cbase
        "::"
      when :kwbegin
        Concat.new(
          "begin",
          Indent.new(
            Hardline.new,
            visit(node.children[0])
          ),
          Hardline.new,
          "end"
        )
      when :ensure
        Concat.new(
          Indent.new(
            visit(node.children[0]),
          ),
          Dedent.new(
            Hardline.new,
            "ensure",
          ),
          Hardline.new,
          visit(node.children[1]),
        )
      when :rescue
        Concat.new(
          visit(node.children[0]),
          Dedent.new(
            Hardline.new,
            visit(node.children[1])
          )
        )
      when :resbody
        args = node.children[0]
        assignment = node.children[1]
        body = node.children[2]

        arguments = if args
          Concat.new(
            " ",
            visit(args),
          )
        end

        argument_assignment = if assignment
          Concat.new(
            " => ",
            visit(assignment)
          )
        end

        body = if body
          visit(body)
        end

        Concat.new(
          "rescue",
          arguments,
          argument_assignment,
          Indent.new(
            Hardline.new,
            body,
          )
        )
      when :nth_ref
        Concat.new(
          "$",
          node.children[0].to_s,
        )
      when :super
        Concat.new(
          "super(",
          *visit_each(node.children),
          ")"
        )
      when :zsuper
        "super"
      when :block_pass
        Concat.new("&", visit(node.children[0]))
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
