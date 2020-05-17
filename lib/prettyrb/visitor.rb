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

    attr_reader :output, :current_line

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

    def write(input, skip_indent: false)
      if @newline
        @output << indents unless skip_indent
        @current_line << indents unless skip_indent
      end
      @newline = false
      @output << input
      @current_line << input
    end

    def visit(node)
      case node.type
      when :module
        write "module "
        visit node.children[0]
        newline

        indent do
          visit node.children[1] if node.children[1]
        end

        newline unless @output[-1] == "\n"
        write "end"
        newline
      when :class
        newline unless @previous_node.nil?
        write "class "
        visit node.children[0]

        if node.children[1]
          write " < "
          visit node.children[1]
        end

        newline

        indent do
          visit node.children[2] if node.children[2]
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
        visit node.children[2]
      when :cvasgn
        write node.children[0].to_s
        write " = "
        visit node.children[1]
      when :cvar
        write node.children[0].to_s
      when :block
        newline unless @previous_node.nil?
        visit node.children[0]
        write " do"

        if node.children[1].children.length > 0
          write " |"
          visit node.children[1]
          write "|"
        end

        newline

        indent do
          visit node.children[2]
        end

        newline

        write "end"
      when :send
        newline if node.parent&.type == :begin && @previous_node && @previous_node&.type != :send

        if node.called_on_heredoc?
          visit node.target
        elsif node.heredoc_arguments?
          Prettyrb::Correcter::HeredocInMethod.new(node: node, visitor: self).perform
        elsif node.target == nil
          write node.method.to_s

          if node.arguments.length > 0
            write "("
            indent do
              if splittable_separated_map(node, node.arguments) == MULTI_LINE
                newline
              end
            end
            write ")"
          end

          newline if @previous_node&.type == :class 
        elsif node.array_assignment?
          visit node.target
          write "["
          visit node.children[2]
          write "]"
          if !node.left_hand_mass_assignment?
            write " = "
          end
          visit node.children[3] if node.children[3]
        elsif node.array_access?
          visit node.target
          write "["
          visit node.children[2]
          write "]"
        elsif node.negate?
          write "!"
          visit node.target
        elsif node.negative?
          write "-"
          visit node.target
        elsif node.self_target?
          write node.method.to_s[0..-2]
          visit node.target
        elsif node.infix?
          visit node.target
          write " "
          write node.method.to_s
          write " "
          visit node.children[2]
        else
          visit node.target
          write "."

          if node.left_hand_mass_assignment?
            write node.method.to_s[0..-2]
          else
            write node.method.to_s
          end

          if node.arguments.length > 0
            write "("
            if splittable_separated_map(node, node.arguments) == MULTI_LINE
              newline
            end
            write ")"
          end
        end
      when :if
        newline if @previous_node && node.parent&.type != :if
        conditions = node.conditions_node

        write node.if_type

        conditions = capture do
          visit node.children[0]
        end

        indent do
          if !conditions.start_with?("\n")
            write(" ")
            write conditions
          else
            visit node.conditions_node

            dedent do
              newline
              write "then"
            end
          end

          newline
          visit node.body_node
        end

        newline

        if node.else_body_node
          if node.has_elsif?
            visit node.else_body_node
          else
            write "else"
            newline

            indent do
              visit node.else_body_node
            end

            newline
          end
        end

        if !node.is_elsif?
          write "end"
        end
      when :true
        write "true"
      when :false
        write "false"
      when :nil
        write "nil"
      when :int, :float
        write node.children[0].to_s
      when :next
        write "next"

        if node.children[0]
          write " "
          visit node.children[0]
        end
      when :array
        if node.children[0]&.type == :splat
          visit node.children[0]
        else
          write "[" unless node.parent&.type == :resbody
          if node.children.length > 0
            indent do
              result = splittable_separated_map(node, node.children)
              newline if result == MULTI_LINE
            end
          end
          write "]" unless node.parent&.type == :resbody
        end
      when :str, :dstr
        if node.heredoc?
          Prettyrb::Correcter::HeredocMethodChain.new(node: node, visitor: self).perform

          newline
          write node.heredoc_body, skip_indent: true
          @newline = true
          write node.heredoc_identifier
          newline
        elsif node.percent_string?
          write "%"
          write node.percent_character
          write node.start_delimiter
          node.children.map do |child|
            if child.is_a?(String)
              write child
            elsif child.type == :str
              write child.format
            else
              write '#{'
              visit child
              write '}'
            end
          end
          write node.closing_delimiter
        else
          write '"'
          if node.type == :str
            write node.format
          else
            node.children.map do |child|
              if child.type == :str
                write child.format
              else
                write '#{'
                visit child
                write '}'
              end
            end
          end
          write '"'
        end
      when :break
        write "break"
      when :begin
        if @previous_node&.type == :or || @previous_node&.type == :and
          write "("
          @previous_node = nil
          node.children.map do |child|
            visit child
            @previous_node = child
          end
          @previous_node = nil
          write ")"
        else
          @previous_node = nil
          node.children.each_with_index do |child, index|
            visit child
            newline unless index == node.children.length - 1
            @previous_node = child
          end
          @previous_node = nil
        end
      when :or, :and
        write "(" if node.parent&.type == :begin
        possible_output = capture do
          visit node.children[0]
          if node.type == :or
            write " || "
          elsif node.type == :and
            write " && "
          end
          visit node.children[1]
        end
        if @multiline_conditional_level > 0 # TODO track and check currently level
          write_multiline_conditional(node)
        elsif possible_output.length > MAX_LENGTH
          in_multiline_conditional do
            newline
            write_multiline_conditional(node)
          end
        else
          write possible_output
        end
        write ")" if node.parent&.type == :begin
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
          visit arguments_node
          write ")"
        end
        newline

        if body_node
          indent do
            visit body_node
          end

          newline
        end

        write "end"
      when :args
        node.children.each_with_index do |child, index|
          visit child
          write ", " unless index == node.children.length - 1
        end
      when :arg
        write node.children[0].to_s
      when :lvar, :gvar
        write node.children[0].to_s
      when :self
        write "self"
      when :sym
        content = node.children[0].to_s

        # TODO handle already quoted symbols
        if !VALID_SYMBOLS.include?(content) && !content.match?(/\A[a-zA-Z_]{1}[a-zA-Z0-9_!?=]*\z/)
          content = "'#{content}'"
          write ":"
          write content
        else
          if node.parent&.type == :pair && node.parent.children[0] == node
            write content
            write ": "
          else
            write ":"
            write content
          end
        end
      when :return
        write "return"

        if node.children[0]
          possible_output = capture do
            visit node.children[0]
          end

          if !possible_output.start_with?("\n")
            write " "
          end
        end
      when :case
        write "case "
        visit node.children[0] if node.children[0]
        newline
        node.children[1..-1].each do |child|
          if child && child.type != :when
            write "else"
            newline

            indent do
              visit child
            end
          else
            if child
              visit child
              newline
            end
          end
        end
        newline unless output.end_with?("\n")
        write "end"
      when :regexp
        if node.percent?
          write "%"
          write node.percent_type
          write node.start_delimiter
        else
          write '/'
        end
        node.children[0...-1].map do |child_node|
          if child_node.string?
            write child_node.children[0].to_s
          else
            visit child_node
          end
        end
        if node.percent?
          write node.end_delimiter
        else
          write '/'
        end
        visit node.children[-1]
      when :regopt
        write node.children.map { |child| child.to_s }.join('')
      when :when
        write "when"

        indent do
          splittable_separated_map(node, node.children[0..-2], skip_last_multiline_separator: true, write_space_if_single_line: true)
        end

        newline
        indent do
          visit node.children[-1]
        end
      when :or_asgn, :and_asgn
        newline if @previous_node && ![:ivasgn, :or_asgn, :lvasgn, :op_asgn].include?(@previous_node.type)
        visit node.children[0]
        if node.type == :or_asgn
          write " ||= " # TODO handle long lines here too
        elsif node.type == :and_asgn
          write " &&= " # TODO handle long lines here too
        end
        visit node.children[1]
      when :ivasgn
        newline if @previous_node && ![:ivasgn, :or_asgn, :lvasgn, :op_asgn].include?(@previous_node.type)
        write node.children[0].to_s

        if node.children[1]
          write " = "
          visit node.children[1]
        end
      when :csend
        visit node.children[0]
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
        visit node.children[0]
        write " "
        write node.children[1].to_s
        write "="
        write " "
        visit node.children[2]
      when :lvasgn
        newline if @previous_node && ![:ivasgn, :or_asgn, :lvasgn, :op_asgn].include?(@previous_node.type)
        write node.children[0].to_s
        if node.children[1]
          write " = "
          visit node.children[1]
        end
      when :irange
        visit node.children[0] unless node.children[0].nil?
        write ".."
        visit node.children[1] unless node.children[1].nil?
      when :erange
        visit node.children[0] unless node.children[0].nil?
        write "..."
        visit node.children[1] unless node.children[1].nil?
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
        visit node.children[0]
        if node.children[0].type != :sym
          write " => "
        end
        visit node.children[1]
      when :splat
        write "*"
        visit node.children[0]
      when :defined?
        write "defined?("
        visit node.children[0]
        write ")"
      when :dsym
        write ":\""
        node.children.each do |child|
          if child.string?
            write child.children[0]
          else
            write "\#{"
            visit child
            write "}"
          end
        end
        write "\""
      when :complex,
        :xstr,
        :'nth-ref',
        :'back-ref',
        :gvasgn,
        :procarg0,
        :shadowarg
        raise "implement me, #{node.inspect}"
      when :sclass
        write "class << "
        visit node.children[0]
        newline

        indent do
          visit node.children[1] if node.children[1]
        end

        newline if node.children[1]
        write "end"
      when :undef
        write "undef "
        node.children.each_with_index do |child_node, index|
          visit child_node
          write ", " unless index == node.children.length - 1
        end
      when :alias
        write 'alias '
        visit node.children[0]
        write ' '
        visit node.children[1]
      when :restarg
        write "*"
        write node.children[0].to_s
      when :optarg
        write node.children[0].to_s
        write " = "
        visit node.children[1]
      when :kwsplat
        write "**"
        visit node.children[0]
      when :kwarg
        write node.children[0].to_s
        write ":"
      when :forward_args, :forwarded_args
        write "..."
      when :kwoptarg
        write node.children[0].to_s
        write ": "
        visit node.children[1]
      when :kwrestarg
        write "**"
        write node.children[0].to_s if node.children[0]
      when :kwnilarg
        write "**nil"
      when :cbase
        write "::"
      when :zsuper
        write "super"
      when :super
        write "super("
        splittable_separated_map(node, node.children)
        write ")"
      when :nth_ref
        write "$"
        write node.children[0].to_s
      when :masgn
        left = node.children[0...-1]
        right = node.children[-1]

        left.each_with_index do |child_node, index|
          visit child_node
        end

        write " = "
        visit right
      when :mlhs
        write "(" if node.parent&.type == :mlhs
        node.children.each_with_index do |child_node, index|
          visit child_node
          write ", " unless index == node.children.length - 1
        end
        write ")" if node.parent&.type == :mlhs
      when :block_pass
        write "&"
        visit node.children[0]
      when :kwbegin
        write "begin"
        newline
        indent do
          visit node.children[0]
        end
        newline
        write "end"
      when :rescue
        visit node.children[0]
        newline

        dedent do
          write "rescue"
          visit node.children[1]
        end
      when :resbody
        if node.children[0]
          write " "
          visit node.children[0] if node.children[0]
        end

        if node.children[1]
          write " => "
          write node.children[1].children[0].to_s
        end
        newline

        indent do
          visit node.children[2] if node.children[2]
        end
      when :ensure
        visit node.children[0] if node.children[0]
        newline

        dedent do
          write "ensure"
        end

        newline
        visit node.children[1] if node.children[1]
      else
        raise "unhandled node type `#{node.type}`\nnode: #{node}"
      end
    end

    def write_multiline_conditional(node)
      visit node.children[0]

      if node.type == :or
        write " ||"
      elsif node.type == :and
        write " &&"
      end

      newline

      visit node.children[1]
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
          visit child_node
          write separator unless index == mappable.length - 1
        end
      end

      if @current_line.length + one_line.length > MAX_LENGTH
        mappable.each_with_index do |child_node, index|
          newline
          visit child_node

          if !skip_last_multiline_separator || index != mappable.length - 1 
            write separator.rstrip 
          end
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
