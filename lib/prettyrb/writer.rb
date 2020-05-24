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
      when Join
        builder.parts.map do |part|
          write_child(part)
        end.compact.join("")
      when Concat
        builder.parts.map do |part|
          write_child(part)
        end.compact.join(" ")
      when String, Symbol
        builder.to_s
      when Indent
        builder.parts.map do |part|
          indent_string(extra: 1) + write_child(part, indent_level: indent_level + 1)
        end.join("")
      when Group
        builder.parts.each_with_index.map do |part, index|
          write_child(part, group_level: group_level + 1)
        end.join("")
      when SplittableGroup
        content = builder.prefix + builder.parts.map do |part|
          write_child(part, group_level: group_level + 1)
        end.join(builder.joiner + " ") + builder.suffix

        if content.length > 100
          [
            builder.prefix,
            builder.parts.map do |part|
              indent_string(extra: 1) + write_child(part, group_level: group_level + 1)
            end.join(builder.joiner + "\n"),
            indent_string + builder.suffix,
          ].join("\n")
        else
          content
        end
      when Hardline
        "\n"
      when Softline
        if indent_group_level >= group_level
          "\n"
        else
          builder.fallback
        end
      when nil
        nil
      else
        raise "unhandled type: #{builder.class}"
      end
    end

    private

    attr_reader :builder, :writer, :indent_level, :group_level, :indent_group_level

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
