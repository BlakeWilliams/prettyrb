module Prettyrb
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

    attr_reader :output

    def initialize
      @indent_level = 0
      @output = ""

      @newline = true
      @multiline_conditional_level = 0
      @previous_node = nil
      @current_line = ''
    end

    def indents
      '  ' * @indent_level
    end

    def dedent(&block)
      old_indent_level = @indent_level

      @indent_level = [0, @indent_level - 1].max
      yield
      @indent_level = old_indent_level
    end

    def indent(&block)
      old_indent_level = @indent_level
      old_previous_node = @previous_node

      @previous_node = nil
      @indent_level += 1
      value = yield
      @indent_level = old_indent_level
      @previous_node = old_previous_node
      value
    end

    def multiline_conditional_level
      @multiline_conditional_level
    end

    def in_multiline_conditional(&block)
      old_multiline_condtiional_level = @multiline_conditional_level
      @multiline_conditional_level += 1
      @multiline_condtiional_level = 0
      yield
      @multiline_conditional_level = old_multiline_condtiional_level
    end

    def capture(&block)
      old_newline = @newline
      old_output = @output
      old_current_line = @current_line

      @current_line = ""
      @output = ""

      yield

      @output.tap do |output|
        @output = old_output
        @newline = old_newline
        @current_line = old_current_line
      end
    end

    def newline
      @output << "\n"
      @newline = true
      @current_line = ''
    end

    def write(input)
      if @newline
        @output << indents
        @current_line << indents
      end
      @newline = false
      @output << input
      @current_line << input
    end

    def visit(node, parent_node)
      case node.type
      when :module
        write "module "
        visit node.children[0], node
        newline

        indent do
          visit node.children[1], node
        end

        write "end"
        newline
      when :class
        newline unless @previous_node.nil?
        write "class "
        visit node.children[0], node
        newline
        # TODO handle children[1] which is inheritance

        indent do
          visit node.children[2], node
        end

        newline unless @output.end_with?("\n")
        write "end"
        newline
      when :const
        visit node.children[0] if node.children[0]
        write node.children[1].to_s
      when :casgn
        write node.children[1].to_s
        write " = "
        visit node.children[2], node
      when :block
        newline unless @previous_node.nil?
        visit node.children[0], node
        write " do"

        if node.children[1].children.length > 0
          write " |"
          visit node.children[1], node
          write "|"
        end

        newline

        indent do
          visit node.children[2], node
        end

        newline

        write "end"
      when :send
        newline if parent_node&.type == :begin && @previous_node && @previous_node&.type != :send
        if node.children[0] == nil
          write node.children[1].to_s

          # TODO possible > MAX via `capture`
          arguments = node.children[2..-1]
          if arguments.length > 0
            write "("
            indent do
              if splittable_separated_map(node, arguments) == MULTI_LINE
                newline
              end
            end
            write ")"
          end

          newline if @previous_node&.type == :class 
        elsif node.children[1] == :[]
          visit node.children[0], node
          write "["
          visit node.children[2], node
          write "]"
        elsif node.children[1] == :!
          write "!"
          visit node.children[0], node
        elsif !node.children[1].to_s.match?(/[a-zA-Z]/)
        # if [:!=, :==, :+, :-, :*, :/, :<<, :<].include?(node.children[1])
          visit node.children[0], node
          write " "
          write node.children[1].to_s
          write " "
          visit node.children[2], node
        else
          visit node.children[0], node
          write "."
          write node.children[1].to_s

          # TODO possible > MAX via `capture`
          arguments = node.children[2..-1]
          if arguments.length > 0
            write "("
            arguments.each_with_index do |child_node, index|
              visit child_node, node
              write ", " unless index == arguments.length - 1
            end
            write ")"
          end
        end
      when :if
        newline unless @previous_node.nil?

        is_unless = node.children[1].nil?
        conditions = node.children[0]

        if is_unless
          write "unless"
          body_node = node.children[2]
          else_body_node = nil
        else
          write "if" unless parent_node&.type == :if
          body_node = node.children[1]
          else_body_node = node.children[2]
        end

        indent do
          conditions = capture do
            visit node.children[0], node
          end

          if !conditions.start_with?("\n")
            write(" ")
          end

          write conditions
          newline

          if body_node
            visit body_node, node
            newline
          end
        end

        if else_body_node
          if else_body_node.type == :if
            write "elsif"
            visit else_body_node, node
          else
            write "else"
            newline

            indent do
              visit else_body_node, node
            end
          end
          newline
        end

        write "end" unless parent_node&.type == :if
      when :true
        write "true"
      when :false
        write "false"
      when :nil
        write "nil"
      when :int, :float
        write node.children[0].to_s
      when :array
        if node.children[0].type == :splat
          visit node.children[0], node
        else
          write "["
          indent do
            result = splittable_separated_map(node, node.children)
            newline if result == MULTI_LINE
          end
          write "]"
        end
      when :str
        write '"'
        write format_string(node)
        write '"'
      when :dstr
        write "\""
        node.children.map do |child|
          if child.type == :str
            write child.children[0] # TODO better handling
          else
            write '#{'
            visit child, node
            write '}'
          end
        end
        write "\""
      when :begin
        if @previous_node&.type == :or || @previous_node&.type == :and
          write "("
          @previous_node = nil
          node.children.map do |child|
            visit child, node
            @previous_node = child
          end
          @previous_node = nil
          write ")"
        else
          @previous_node = nil
          node.children.each_with_index do |child, index|
            visit child, node
            newline unless index == node.children.length - 1
            @previous_node = child
          end
          @previous_node = nil
        end
      when :or, :and
        write "(" if parent_node&.type == :begin
        possible_output = capture do
          visit node.children[0], node
          if node.type == :or
            write " || "
          elsif node.type == :and
            write " && "
          end
          visit node.children[1], node
        end
        if @multiline_conditional_level > 0 # TODO track and check currently level
          write_multiline_conditional(node)
        elsif possible_output.length > MAX_LENGTH
          in_multiline_conditional do
            newline
            write_multiline_conditional(node)
          end

          dedent do
            newline
            write "then"
          end
        else
          write possible_output
        end
        write ")" if parent_node&.type == :begin
      when :def, :defs
        newline unless @previous_node&.type.nil?
        if node.type == :defs
          write "def self."
          method_name_node = node.children[1]
          arguments_node = node.children[2]
          body_node = node.children[3]
        else
          write "def "
          method_name_node = node.children[0]
          arguments_node = node.children[1]
          body_node = node.children[2]
        end

        write method_name_node.to_s

        if arguments_node.children.length > 0 || arguments_node.type != :args
          write "("
          visit arguments_node, node
          write ")"
        end
        newline

        if body_node
          indent do
            visit body_node, node
          end

          newline
        end

        write "end"
      when :args
        node.children.each_with_index do |child, index|
          visit child, node
          write ", " unless index == node.children.length - 1
        end
      when :arg
        write node.children[0].to_s
      when :lvar, :gvar
        write node.children[0].to_s
      when :self
        "self"
      when :sym
        content = node.children[0].to_s

        # TODO handle already quoted symbols
        if !VALID_SYMBOLS.include?(content) && !content.match?(/\A[a-zA-Z_]{1}[a-zA-Z0-9_!?]*\z/)
          content = "'#{content}'"
          write ":"
          write content
        else
          if parent_node&.type == :pair
            write content
            write ": "
          else
            write ":"
            write content
          end
        end
      when :return
        write "return"

        possible_output = capture do
          visit node.children[0], node
        end

        if !possible_output.start_with?("\n")
          write " "
        end
      when :case
        write "case "
        visit node.children[0], node
        newline
        node.children[1..-1].each do |child|
          if child && child.type != :when
            write "else"
            newline

            indent do
              visit child, node
            end
          else
            if child
              visit child, node
              newline
            end
          end
        end
        write "end"
      when :regexp
        write '/'
        node.children[0...-1].map do |child_node|
          if child_node.type == :str
            write child_node.children[0].to_s
          else
            visit child_node, node
          end
        end
        write '/'
        visit node.children[-1], node
      when :regopt
        node.children.map { |child| child.to_s }.join('')
      when :when
        write "when"

        indent do
          splittable_separated_map(node, node.children[0..-2], skip_last_multiline_separator: true, write_space_if_single_line: true)
          # node.children[0...-1].each_with_index do |child_node, index|
          #   visit child_node, node
          #   write ', ' unless index == node.children.length - 2
          # end
        end

        newline
        indent do
          visit node.children[-1], node
        end
      when :or_asgn, :and_asgn
        newline if @previous_node && ![:ivasgn, :or_asgn, :lvasgn, :op_asgn].include?(@previous_node.type)
        visit node.children[0], node
        if node.type == :or_asgn
          write " ||= " # TODO handle long lines here too
        elsif node.type == :and_asgn
          write " &&= " # TODO handle long lines here too
        end
        visit node.children[1], node
      when :ivasgn
        newline if @previous_node && ![:ivasgn, :or_asgn, :lvasgn, :op_asgn].include?(@previous_node.type)
        write node.children[0].to_s

        if node.children[1]
          write " = "
          visit node.children[1], node
        end
      when :csend
        visit node.children[0], node
        write "&."
        write node.children[1].to_s
      when :ivar
        write node.children[0].to_s
      when :blockarg
        write '&'
        write node.children[0].to_s
      when :yield
        newline unless @previous_node.nil? || [:op_asgn, :lvasgn, :or_asgn, :and_asgn].include?(@previous_node.type)
        write "yield"
      when :op_asgn
        newline if @previous_node && ![:ivasgn, :or_asgn, :lvasgn, :op_asgn].include?(@previous_node.type)
        visit node.children[0], node
        write " "
        write node.children[1].to_s
        write "="
        write " "
        visit node.children[2], node
      when :lvasgn
        newline if @previous_node && ![:ivasgn, :or_asgn, :lvasgn, :op_asgn].include?(@previous_node.type)
        write node.children[0].to_s
        if node.children[1]
          write " = "
          visit node.children[1], node
        end
      when :irange
        visit node.children[0], node unless node.children[0].nil?
        write ".."
        visit node.children[1], node unless node.children[1].nil?
      when :erange
        visit node.children[0], node unless node.children[0].nil?
        write "..."
        visit node.children[1], node unless node.children[1].nil?
      when :hash
        if node.children.length == 0
          write "{}"
        else
          write "{"

          result = indent do
            splittable_separated_map(node, node.children, write_space_if_single_line: true)
          end

          if result == MULTI_LINE
            newline
            write "}"
          else
            write " }"
          end
        end
      when :pair
        visit node.children[0], node
        if node.children[0].type != :sym
          write " => "
        end
        visit node.children[1], node
      when :splat
        write "*"
        visit node.children[0], node
      when :defined?
        write "defined?"
        visit node.children[0]
      when :complex,
        :dsym,
        :xstr,
        :'nth-ref',
        :'back-ref',
        :gvasgn,
        :mlhs,
        :procarg0,
        :shadowarg
        raise "implement me, #{node.inspect}"
      when :sclass
        write "class << "
        visit node.children[0], node
        newline

        indent do
          visit node.children[1], node if node.children[1]
        end

        newline if node.children[1]
        write "end"
      when :undef
        write "undef "
        node.children.each_with_index do |child_node, index|
          visit child_node, node
          write ", " unless index == node.children.length - 1
        end
      when :alias
        write 'alias '
        visit node.children[0], node
        write ' '
        visit node.children[1], node
      when :restarg
        write "*"
        write node.children[0].to_s
      when :optarg
        write node.children[0].to_s
        write " = "
        visit node.children[1], node
      when :kwsplat
        write "**"
        visit node.children[0], node
      when :kwarg
        write node.children[0].to_s
        write ":"
      when :forward_args, :forwarded_args
        write "..."
      when :kwoptarg
        write node.children[0].to_s
        write ": "
        visit node.children[1], node
      when :kwrestarg
        write "**"
        write node.children[0].to_s if node.children[0]
      when :kwnilarg
        write "**nil"
      else
        raise "unhandled node type `#{node.type}`\nnode: #{node}"
      end
    end

    def write_multiline_conditional(node)
      visit node.children[0], node

      if node.type == :or
        write " ||"
      elsif node.type == :and
        write " &&"
      end

      newline

      visit node.children[1], node
    end

    def format_string(string)
      raw_content = string.loc.expression.source
      content = raw_content[1...-1]

      if raw_content[0] == "'"
        content.gsub('"', '\\"').gsub('#{', '\\#{')
      else
        content.gsub("\\", "\\\\")
      end
    end

    def splittable_separated_map(current_node, mappable, separator: ", ", skip_last_multiline_separator: false, write_space_if_single_line: false)
      one_line = capture do
        mappable.each_with_index do |child_node, index|
          visit child_node, current_node
          write separator unless index == mappable.length - 1
        end
      end

      if @current_line.length + one_line.length > MAX_LENGTH
        mappable.each_with_index do |child_node, index|
          newline
          visit child_node, current_node
          write separator.rstrip unless skip_last_multiline_separator && index == mappable.length - 1
        end
        MULTI_LINE
      else
        write ' ' if write_space_if_single_line
        write one_line
        SINGLE_LINE
      end
    end
  end
end
