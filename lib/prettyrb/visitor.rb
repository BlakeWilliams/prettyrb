module Prettyrb
  class Visitor
    include Document::DSL

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
      when :module
        body = if node.children[1]
          concat(
            indent(
              hardline,
              visit(node.children[1]),
            ),
            hardline
          )
        end

        concat(
          "module ",
          visit(node.children[0]),
          body,
          "end"
        )
      when :sclass
        body = if node.children[1]
          concat(
            indent(
              hardline,
              visit(node.children[1]),
            ),
            hardline,
          )
        end

        concat(
          "class << ",
          visit(node.children[0]),
          body,
          "end"
        )
      when :class
        inheritance = if node.children[1]
          concat(
            " < ",
            visit(node.children[1]),
          )
        end

        content = if node.children[2]
          indent(
            hardline,
            visit(node.children[2]),
          )
        end

        concat(
          "class ",
          visit(node.children[0]),
          inheritance,
          content,
          hardline,
          "end"
        )
      when :if
        body = if node.body_node
          concat(
            indent(
              hardline,
              visit(node.body_node),
            ),
          )
        end

        elsifs = if node.has_elsif?
          [hardline] + node.elsif_branches.map do |elsif_branch|
            concat(
              "elsif ",
              visit(elsif_branch.conditions),
              indent(
                hardline,
                visit(elsif_branch.body_node)
              ),
              hardline,
            )
          end
        end

        else_content = if node.else_branch
          starting_newline = if !node.has_elsif?
            hardline
          end
          concat(
            starting_newline,
            "else",
            indent(
              hardline,
              visit(node.else_branch)
            ),
            hardline,
          )
        else
          hardline
        end

        concat(
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
          concat(
            " ",
            visit(node.children[0]),
          )
        end

        cases = node.children[1..-1].map do |child|
          if child && child.type != :when
            concat(
              hardline,
              "else",
              indent(
                hardline,
                visit(child)
              ),
            )
          elsif child
            visit child
          end
        end

        concat(
          "case",
          arguments,
          concat(*cases),
          hardline,
          "end"
        )
      when :when
        arguments = node.children[0..-2].compact
        body = if node.children.last
          indent(
            hardline,
            visit(node.children.last)
          )
        end

        arguments = if arguments.size > 0
          join(
            separator: ",",
            parts: arguments.map do |arg|
              concat(softline, visit(arg))
            end
          )
        end

        concat(
          hardline,
          group(
            "when",
            if_break(with_break: "", without_break: " "),
            indent(
              arguments,
            ),
          ),
          body
        )
      when :const
        output = []

        child = node.children[0]
        while child&.type == :const || child&.type == :cbase
          output << child.children[1]
          child = child.children[0]
        end

        (output.reverse + [node.children[1]]).join("::")
      when :or
        builder = concat(
          visit(node.children[0]),
          " ||",
          if_break(with_break: "", without_break: " "),
          softline,
          visit(node.children[1]),
        )

        if node.parent&.type == :and || node.parent&.type == :or
          builder
        else
          group(
            indent(
              builder
            )
          )
        end
      when :and
        builder = concat(
          visit(node.children[0]),
          " &&",
          if_break(with_break: "", without_break: " "),
          softline,
          visit(node.children[1]),
        )

        if node.parent&.type == :and || node.parent&.type == :or
          builder
        else
          group(
            indent(
              builder
            )
          )
        end
      when :int
        node.children[0].to_s
      when :return
        if node.children[0]
          group(
            "return",
            if_break(without_break: " ", with_break: ""),
            indent(
              softline,
              visit(node.children[0]),
              only_when_break: true
            )
          )
        else
          "return"
        end
      when :block
        args = if node.children[1]&.children&.length > 0
          concat(
            " |",
            visit(node.children[1]),
            "|",
          )
        end

        concat(
          visit(node.children[0]),
          " do",
          args,
          indent(
            hardline,
            visit(node.children[2]),
          ),
          hardline,
          "end",
        )
      when :begin
        needs_parens = (node.parent&.type == :if && node.parent.children[0] == node) ||
          node.parent&.type == :or ||
          node.parent&.type == :and ||
          node.parent&.type == :send

        if needs_parens
          concat(
            "(",
            *visit_each(node.children), # TODO Split or softline?
            ")"
          )
        else
          children = []
          node.children.each_with_index do |child, index|
            children << visit(child)

            next_child = node.children[index + 1]
            excluded_types = [:class, :module, :sclass, :def, :defs]

            if (excluded_types.include?(child.type) && node.children.last != child) ||
                (next_child&.type != child.type && node.children.last != child)
              children << hardline(count: 2)
            elsif node.children.last != child
              children << hardline
            end
          end

          concat(*children)
        end
      when :defs
        args_blocks = visit node.children[2] if node.children[2]

        body = if node.children[3]
          concat(
            indent(
              hardline,
              visit(node.children[3]),
            ),
            hardline,
          )
        else
          hardline
        end

        concat(
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
          concat(
            indent(
              hardline,
              body_blocks,
            ),
            hardline,
          )
        else
          hardline
        end

        concat(
          "def ",
          # TODO possible break
          node.name,
          args_blocks,
          body,
          "end",
        )
      when :args
        if node&.parent&.type == :block
          group(
            join(
              separator: ",",
              parts: node.children.map(&method(:visit)),
            ),
          )
        elsif node.children.length > 0
          group(
            "(",
            softline,
            join(
              separator: ",",
              parts: node.children.map(&method(:visit)),
            ),
            softline,
            ")"
          )
        else
          nil
        end
      when :arg
        node.children[0]
      when :masgn
        concat(
          visit(node.children[0]),
          " = ",
          visit(node.children[-1])
        )
      when :mlhs
        if node.parent&.type == :mlhs
          concat(
            "(",
            join(separator: ",", parts: visit_each(node.children)),
            ")"
          )
        else
          join(separator: ",", parts: visit_each(node.children))
        end
      when :casgn
        if !node.children[0].nil?
          puts "FATAL: FIX CASGN FIRST ARGUMENT"
          exit 1
        end

        # TODO test softline grouping on right side of `=`
        group(
          node.children[1],
          " = ",
          # if_break(with_break: "", without_break: " "),
          # softline,
          visit(node.children[2]),
        )
      when :lvasgn, :cvasgn, :ivasgn
        right_blocks = visit node.children[1] if node.children[1]

        if right_blocks
          concat(
            node.children[0].to_s,
            " = ",
            # TODO line break for long lines
            right_blocks,
          )
        else
          concat(
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

          concat(
            visit(node.target),
            "[",
            visit(node.children[2]),
            "]", # TODO line split
            equals,
            body,
          )
        elsif node.array_access?
          concat(
            visit(node.target),
            "[",
            visit(node.children[2]),
            "]"
          )
        elsif node.negate?
          concat(
            "!",
            visit(node.target),
          )
        elsif node.negative?
          concat(
            "-",
            visit(node.target),
          )
        elsif node.self_target?
          body = visit(node.target) if node.target

          concat(
            node.method.to_s[0..-2],
            body,
          )
        elsif node.infix?
          body = visit(node.children[2]) if node.children[2]

          group(
            concat(
              visit(node.target),
              " ",
              node.method,
              " ",
              body,
            )
          )
        else
          arguments = if node.arguments.length > 0
            concat(
              "(",
              indent(
                join(separator: ",", parts: node.arguments.map { |child| concat(softline, visit(child)) }),
                only_when_break: true,
              ),
              softline,
              ")",
            )
          end

          method = if node.left_hand_mass_assignment?
            node.method.to_s[0...-1]
          else
            node.method
          end

          if node.target
            concat(
              visit(node.target),
              ".",
              method,
              group(
                arguments,
              )
            )
          else
            concat(
              method,
              group(
                arguments,
              )
            )
          end
        end
      when :hash
        if node.children.length > 0
          group(
            "{",
            if_break(without_break: " ", with_break: ""),
            indent(
              join(separator: ",", parts: node.children.map { |child| concat(softline, visit(child)) }),
              if_break(without_break: " ", with_break: ""),
            ),
            softline,
            "}"
          )
        else
          "{}"
        end
      when :pair
        if node.children[0].type == :sym
          concat(
            visit(node.children[0]),
            visit(node.children[1])
          )
        else
          concat(
            visit(node.children[0]),
            " => ",
            visit(node.children[1])
          )
        end
      when :defined?
        concat(
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

        group(
          visit(node.children[0]),
          " ",
          operator,
          if_break(with_break: "", without_break: " "),
          softline,
          visit(node.children[1])
        )
      when :array
        if node.parent&.type == :resbody
          join(separator: ",", parts: visit_each(node.children))
        elsif node.children[0]&.type == :splat
          visit node.children[0]
        else
          array_nodes = node.children.each_with_index.map do |child, index|
            concat(softline, visit(child))
          end

          group(
            "[",
            indent(
              join(separator: ",", parts: array_nodes),
            ),
            softline,
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
          concat(
            "%",
            node.percent_type,
            node.start_delimiter,
            *content,
            node.end_delimiter,
            options,
          )
        else
          concat(
            "/",
            *content,
            "/",
            options,
          )
        end
      when :str, :dstr
        if node.heredoc?
          method_calls = if node.parent&.type == :send
            method_calls = []
            parent = node.parent

            while parent && parent.type == :send && parent.called_on_heredoc?
              arguments = if parent.arguments.length > 0
                concat(
                  "(",
                  join(separator: ",", parts: parent.arguments.map { |child| concat(softline, visit(child)) }),
                  ")",
                )
              end

              method_calls.push(
                concat(
                  ".",
                  parent.children[1].to_s,
                  arguments,
                )
              )
              parent = parent.parent
            end

            concat(*method_calls)
          end

          concat(
            "<<",
            node.heredoc_type,
            node.heredoc_identifier,
            method_calls,
            hardline(skip_indent: true),
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

          concat(
            "%",
            node.percent_character,
            node.start_delimiter,
            *body,
            node.closing_delimiter,
          )
        else
          concat(
            "\"",
            node.format,
            "\"",
          )
        end
      when :alias
        concat(
          "alias ",
          visit(node.children[0]),
          " ",
          visit(node.children[1]),
        )
      when :dsym
        body = node.children.map do |child|
          if child.string?
            child.children[0]
          else
            concat(
              "\#{",
              visit(child),
              "}",
            )
          end
        end

        concat(
          ":\"",
          *body,
          "\"",
        )
      when :sym
        content = node.children[0].to_s

        # TODO handle already quoted symbols
        if !VALID_SYMBOLS.include?(content) && !content.match?(/\A[a-zA-Z_]{1}[a-zA-Z0-9_!?=]*\z/)
          concat(
            ":",
            "'",
            content,
            "'",
          )
        else
          if node.parent&.type == :pair && node.parent.children[0] == node
            concat(
              content,
              ": ",
            )
          else
            concat(
              ":",
              content,
            )
          end
        end
      when :kwsplat
        concat(
          "**",
          visit(node.children[0])
        )
      when :splat
        concat(
          "*",
          visit(node.children[0])
        )
      when :undef
        concat(
          "undef",
          " ",
          join(separator: ",", parts: visit_each(node.children))
        )
      when :forward_args
        "(...)"
      when :forwarded_args
        "..."
      when :optarg
        concat(
          node.children[0],
          " = ",
          visit(node.children[1]),
        )
      when :restarg
        concat(
          "*",
          node.children[0],
        )
      when :kwarg
        concat(
          node.children[0],
          ":",
        )
      when :kwoptarg
        concat(
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
        concat(
          "begin",
          indent(
            hardline,
            visit(node.children[0])
          ),
          hardline,
          "end"
        )
      when :ensure
        concat(
          indent(
            visit(node.children[0]),
          ),
          dedent(
            hardline,
            "ensure",
          ),
          hardline,
          visit(node.children[1]),
        )
      when :rescue
        concat(
          visit(node.children[0]),
          dedent(
            hardline,
            visit(node.children[1])
          )
        )
      when :resbody
        args = node.children[0]
        assignment = node.children[1]
        body = node.children[2]

        arguments = if args
          concat(
            " ",
            visit(args),
          )
        end

        argument_assignment = if assignment
          concat(
            " => ",
            visit(assignment)
          )
        end

        body = if body
          visit(body)
        end

        concat(
          "rescue",
          arguments,
          argument_assignment,
          indent(
            hardline,
            body,
          )
        )
      when :while
        args = if node.children[0]
          concat(
            " ",
            visit(node.children[0])
          )
        end

        body = if node.children[1]
          indent(
            hardline,
            visit(node.children[1]),
          )
        end

        concat(
          "while",
          args,
          body,
          hardline,
          "end",
        )
      when :csend
        concat(
          visit(node.children[0]),
          "&.", # TODO softbreak
          node.children[1]
        )
      when :erange
        right_side = visit(node.children[1]) if node.children[1]

        concat(
          visit(node.children[0]),
          "...",
          right_side
        )
      when :irange
        right_side = visit(node.children[1]) if node.children[1]

        concat(
          visit(node.children[0]),
          "..",
          right_side
        )
      when :nth_ref
        concat(
          "$",
          node.children[0].to_s,
        )
      when :super
        concat(
          "super(",
          *visit_each(node.children),
          ")"
        )
      when :zsuper
        "super"
      when :block_pass
        concat("&", visit(node.children[0]))
      else
        raise "Unexpected node type: #{node.type}"
      end
    end

    private

    def visit_each(node)
      node.map do |child|
        visit(child)
      end
    end
  end
end
