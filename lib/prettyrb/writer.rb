require 'delegate'

module Prettyrb
  class Writer
    extend Forwardable

    def_delegators :@writer, :indent_level

    def initialize(builder, indent_level: 0, group_level: -1, break_group_levels: [], max_length: 100)
      @builder = builder
      @writer = writer
      @indent_level = indent_level
      @group_level = group_level
      @break_group_levels = break_group_levels
      @max_length = max_length
    end

    def to_s
      case builder
      when Document::Join
        separator = break_up? ? builder.separator : builder.separator + " "
        parts = builder.parts.compact

        output = []
        parts.each do |part|
          output << write_child(part)
          output << separator if part != parts.last
          output << "\n" + indent_string if break_up? && part != parts.last
        end
        output.join("")
      when Document::Concat
        builder.parts.compact.map { |p| write_child(p) }.compact.join("")
      when Document::Indent
        builder.parts.compact.map do |part|
          write_child(part, indent_level: indent_level + 1)
        end.compact.join("")
      when Document::Dedent
        builder.parts.compact.map do |part|
          write_child(part, indent_level: indent_level - 1)
        end.compact.join("")
      when Document::Group
        content = builder.parts.compact.map do |part|
          write_child(part, group_level: group_level + 1)
        end.compact.join("")

        if content.split("\n").any? { |line| line.length > max_length }
          max_group_depth = group_level + builder.max_group_depth + 1

          group_level.upto(max_group_depth) do |i|
            content = builder.parts.compact.map do |part|
              write_child(part, group_level: group_level + 1, break_group_levels: [i])
            end.compact.join("")

            if content.split("\n").all? { |line| line.length < max_length }
              return content
            end
          end

          builder.parts.compact.map do |part|
            write_child(part, group_level: group_level + 1, break_group_levels: group_level..max_group_depth)
          end.compact.join("")
        else
          content
        end
      when Document::Hardline
        if builder.skip_indent
          "\n" * builder.count
        else
          "\n" * builder.count + indent_string
        end
      when Document::Softline
        if break_group_levels.include?(group_level)
          "\n" + indent_string
        else
          builder.fallback
        end
      when Document::IfBreak
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

    protected

    attr_reader :builder, :writer, :indent_level, :group_level, :break_group_levels, :max_length

    private

    def break_up?
      break_group_levels.include?(group_level)
    end

    def write_softline?
      break_up?
    end

    def indent_string(extra: 0)
      "  " * (indent_level + extra)
    end

    def write_child(child, indent_level: nil, group_level: nil, break_group_levels: nil)
      indent_level ||= self.indent_level
      group_level ||= self.group_level
      break_group_levels ||= self.break_group_levels

      self.class.new(
        child,
        indent_level: indent_level,
        group_level: group_level,
        break_group_levels: break_group_levels,
        max_length: max_length,
      ).to_s
    end
  end
end
