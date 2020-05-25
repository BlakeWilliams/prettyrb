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
      # when Join
      #   last_part = nil
      #   builder.parts.map do |part|
      #     if last_part && last_part.class == Hardline
      #     else
      #       write_child(part)
      #     end
      #     last_part = part
      #   end.compact.join("")
      # when MultilineJoin
      #   builder.parts.map do |part|
      #     content = write_child(part) if part
      #
      #     if content == "\n"
      #       content
      #     else
      #       indent_string + content.lstrip if part
      #     end
      #   end.compact.join("\n")
      # when Concat
      #   written_parts = builder.parts.each_with_index.map do |part, index|
      #     next_part = builder.parts[index + 1]
      #     if !next_part || next_part&.class == Hardline || (write_softline? && next_part &.class == Softline)
      #       write_child(part)&.gsub(/\A +/, '') if part
      #     else
      #       content = write_child(part)&.gsub(/\A +/, '')
      #       content + " " if content
      #     end
      #   end.compact.join("")
      # when String, Symbol
      #   builder.to_s
      # when Indent
      #   builder.parts.map do |part|
      #     write_child(part, indent_level: indent_level + 1)
      #   end.compact.join("")
      # when Group
      #   attempt = 0
      #   loop do
      #     content = builder.parts.each_with_index.map do |part, index|
      #       indent_string + write_child(part, group_level: group_level + 1, indent_group_level: indent_group_level + attempt)
      #     end.compact.join(builder.joiner)
      #
      #     if content.length < 100 || attempt > 100 # TODO any line?
      #       return content
      #     else
      #       attempt += 1
      #     end
      #   end
      # when SplittableGroup
      #   content = builder.prefix + builder.parts.map do |part|
      #     write_child(part, group_level: group_level + 1)
      #   end.join(builder.joiner + " ") + builder.suffix
      #
      #   if content.length > 100
      #     [
      #       builder.prefix,
      #       builder.parts.map do |part|
      #         indent_string(extra: 1) + write_child(part, group_level: group_level + 1)
      #       end.join(builder.joiner + "\n"),
      #       indent_string + builder.suffix,
      #     ].join("\n")
      #   else
      #     content
      #   end
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
        builder.parts.compact.map { |p| write_child(p) }.compact.join(separator)
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
