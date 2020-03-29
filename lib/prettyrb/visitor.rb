module Prettyrb
  class Visitor
    MAX_LENGTH = 100

    attr_reader :output

    def initialize
      @indent_level = 0
      @output = ""

      @newline = true
      @multiline_conditional_level = 0
      @__current_node = nil
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

      @indent_level += 1
      yield
      @indent_level = old_indent_level
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

      @output = ""

      yield

      @output.tap do |output|
        @output = old_output
        @newline = old_newline
      end
    end

    def newline
      @output << "\n"
      @newline = true
    end

    def write(input)
      if @newline
        @output << indents
      end
      @newline = false
      @output << input
    end

    def visit(node)
      @previous_node = @__current_node
      @__current_node = node

      case node.type
      when :module
        write "module "
        visit node.children[0]
        newline

        indent do
          visit node.children[1]
        end

        write "end"
        newline
      when :class
        write "class "
        visit node.children[0]
        newline
        # TODO handle children[1] which is inheritance

        indent do
          visit node.children[2]
        end

        newline unless @output.end_with?("\n")
        write "end"
        newline
      when :const
        write node.children[1].to_s
      when :casgn
        write node.children[1].to_s
        write " = "
        visit node.children[2]
      when :block
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
        newline
      when :send
        if [:!=, :==, :+, :-, :*, :/, :<<].include?(node.children[1])
          visit node.children[0]
          write " "
          write node.children[1].to_s
          write " "
          visit node.children[2]
        elsif node.children[1] == :[]
          visit node.children[0]
          write "["
          visit node.children[2]
          write "]"
        elsif node.children[1] == :!
          write "!"
          visit node.children[0]
        elsif node.children[0] == nil
          write node.children[1].to_s

          # TODO possible > MAX via `capture`
          arguments = node.children[2..-1]
          if arguments.length > 0
            write "("
            arguments.each_with_index do |node, index|
              visit node
              write ", " unless index == arguments.length - 1
            end
            write ")"
          end

          newline if @previous_node.type == :class 
        else
          visit node.children[0]
          write "."
          write node.children[1].to_s

          # TODO possible > MAX via `capture`
          arguments = node.children[2..-1]
          if arguments.length > 0
            write "("
            arguments.each_with_index do |node, index|
              visit node
              write ", " unless index == arguments.length - 1
            end
            write ")"
          end
        end
      when :if
        write "if"
        indent do
          conditions = capture do
            visit node.children[0]
          end

          if !conditions.start_with?("\n")
            write(" ")
          end
          write conditions

          newline

          if node.children[1]
            visit node.children[1]
            newline
          end
        end

        if node.children[2]
          if node.children[2] == :if
            write "elsif"
            visit node.children[2]
          else
            write "else"
            newline

            indent do
              visit node.children[2]
            end
          end
          newline
        end

        write "end"
      when :true
        write "true"
      when :false
        write "false"
      when :nil
        write "nil"
      when :int
        write node.children[0].to_s
      when :array
        possible_output = capture do
          write "["
          node.children.each_with_index do |child, index|
            visit(child)
            write ", " unless index == node.children.length - 1
          end
          write "]"
        end

        if possible_output.length > MAX_LENGTH
          write "["
          newline

          indent do
            node.children.map do |child|
              visit(child)
              write ","
              newline
            end
          end

          write "]"
        else
          write possible_output.lstrip
        end
      when :str
        write '"'
        write node.children[0].gsub("\n", "\\n")
        write '"'
      when :dstr
        write "\""
        node.children.map do |child|
          if child.type == :str
            write child.children[0]
            write child.children[0].gsub("\n", "\\n")
          else
            write '#{'
            visit child
            write '}'
          end
        end
        write "\""
      when :begin
        if @previous_node.type == :or || @previous_node.type == :and
          write "("
          node.children.map { |child| visit child }
          write ")"
        else
          node.children.each_with_index do |child, index|
            visit child
            newline unless index == node.children.length - 1
          end
        end
      when :or, :and
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

          dedent do
            newline
            write "then"
          end
        else
          write possible_output
        end
      when :def
        write "def "
        write node.children[0].to_s
        if node.children[1].children.length > 0
          write "("
          visit node.children[1]
          write ")"
        end
        newline

        indent do
          visit node.children[2]
        end

        newline
        write "end"
      when :args
        node.children.each_with_index do |child, index|
          visit child
          write ", " unless index == node.children.length - 1
        end
      when :arg
        write node.children[0].to_s
      when :lvar
        write node.children[0].to_s
      when :self
        "self"
      when :sym
        write ":"
        write node.children[0].to_s
      when :return
        write "return"

        possible_output = capture do
          visit node.children[0]
        end

        if !possible_output.start_with?("\n")
          write " "
        end
      when :case
        write "case "
        visit node.children[0]
        newline
        node.children[1..-1].each do |child|
          if child.type != :when
            write "else"
            newline

            indent do
              visit child
            end
          else
            visit child
            newline
          end
        end
        write "end"
      when :when
        write "when "
        visit node.children[0]
        newline
        indent do
          visit node.children[1]
        end
      when :or_asgn
        visit node.children[0]
        write " ||= " # TODO handle long lines here too
        visit node.children[1]
      when :ivasgn
        write node.children[0].to_s
      when :ivar
        write node.children[0].to_s
      when :blockarg
        write node.children[0].to_s
      when :yield
        write "yield"
      when :op_asgn
        visit node.children[0]
        write " "
        write node.children[1].to_s
        write " "
        visit node.children[2]
      when :lvasgn
        write node.children[0].to_s
        write " = "

        visit node.children[1]
      when :irange
        visit node.children[0]
        write ".."
        visit node.children[1]
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
  end
end
