require 'delegate'

module Prettyrb
  class Writer
    extend Forwardable
    def_delegators :@writer, :indent_level

    def initialize(builder, indent_level: 0, group_level: -1, indent_group_level: -2)
      @builder = builder
      @writer = writer
      @indent_level = indent_level
      @group_level = group_level
      @indent_group_level = indent_group_level
    end

    def to_s
      case builder
      when MultilineJoin
        output = []

        builder.parts.each do |part|
          content = write_child(part)
          if content
            output << indent_string + content
            output << "\n"
          end
        end
        output.join("")
      when Join
        separator = break_up? ? builder.separator : builder.separator + " "
        parts = builder.parts.compact

        output = []
        parts.each do |part|
          output << write_child(part)
          output << separator if part != parts.last
        end
        output.join("")
      when Concat
        builder.parts.compact.map { |p| write_child(p) }.compact.join("")
      when Indent
        builder.parts.compact.map do |part|
          write_child(part, indent_level: indent_level + 1)
        end.compact.join("")
      when Group
        attempt = 0

        loop do
          content = builder.parts.compact.map do |part|
            write_child(part, group_level: group_level + 1, indent_group_level: indent_group_level + attempt)
          end.compact.join("")

          if content.length < 100 || attempt > 100
            return content
          else
            attempt += 1
          end
        end
      when Hardline
        "\n" * builder.count + indent_string
      when Softline
        if indent_group_level >= group_level
          "\n" + indent_string
        else
          builder.fallback
        end
      when IfBreak
        if break_up?
          builder.with_break
        else
          builder.without_break
        end
      when Symbol, String
        builder.to_s
      when nil
        nil
      else
        raise "unhandled type: #{builder.class}"
      end
    end

    private

    attr_reader :builder, :writer, :indent_level, :group_level, :indent_group_level

    def break_up?
      indent_group_level >= group_level
    end

    def write_softline?
      break_up?
    end

    def indent_string(extra: 0)
      "  " * (indent_level + extra)
    end

    def write_child(child, indent_level: nil, group_level: nil, indent_group_level: nil)
      indent_level ||= self.indent_level
      group_level ||= self.group_level
      indent_group_level ||= self.indent_group_level

      self.class.new(
        child,
        indent_level: indent_level,
        group_level: group_level,
        indent_group_level: indent_group_level,
      ).to_s
    end
  end
end
