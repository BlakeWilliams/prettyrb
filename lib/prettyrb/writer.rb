require 'delegate'

module Prettyrb
  class Writer
    extend Forwardable

    def_delegators :@writer, :indent_level

    def initialize(builder, indent_level: 0, max_length: Prettyrb::MAX_LINE_LENGTH, force_break: false)
      @builder = builder
      @writer = writer
      @indent_level = indent_level
      @max_length = max_length
      @force_break = force_break
    end

    def render_group(builder)
      # render without force
      # render only non-groups with force
      # render only groups with force
      # render non-groups and groups with force

      # without breaks
      content = builder.parts.compact.map do |part|
        write_child(part, force_break: false)
      end.compact.join("")

      # break self
      if content.split("\n").any? { |l| l.length > max_length }
        content = builder.parts.compact.map do |part|
          write_child(part, force_break: !part.is_a?(Document::Group))
        end.join("")
      end

      # break child groups if over length, but not self
      if content.split("\n").any? { |l| l.length > max_length }
        content = builder.parts.compact.map do |part|
          if part.is_a?(Document::Group)
            possible_output = write_child(part, force_break: false)

            if possible_output && possible_output.split("\n").any? { |l| l.length > max_length }
              content = write_child(part, force_break: true)
            else
              content = possible_output
            end
          else
            write_child(part, force_break: false)
          end
        end.join("")
      end

      # always break self, attempt to break child groups too
      if content.split("\n").any? { |l| l.length > max_length }
        content = builder.parts.compact.map do |part|
          if part.is_a?(Document::Group)
            possible_output = write_child(part, force_break: false)

            if possible_output && possible_output.split("\n").any? { |l| l.length > max_length }
              content = write_child(part, force_break: true)
            else
              content = possible_output
            end
          else
            write_child(part, force_break: true)
          end
        end.join("")
      end

      content
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
        end
        output.join("")
      when Document::Concat
        builder.parts.compact.map { |p| write_child(p) }.compact.join("")
      when Document::Indent
        builder.parts.compact.map do |part|
          if builder.only_when_break && !break_up?
            write_child(part)
          else
            write_child(part, indent_level: indent_level + 1)
          end
        end.compact.join("")
      when Document::Dedent
        builder.parts.compact.map do |part|
          write_child(part, indent_level: indent_level - 1)
        end.compact.join("")
      when Document::Group
        render_group(builder)
      when Document::Hardline
        if builder.skip_indent
          "\n" * builder.count
        else
          "\n" * builder.count + indent_string
        end
      when Document::Softline
        if break_up?
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

    attr_reader :builder, :writer, :indent_level, :break_group_levels, :max_length, :force_break

    private

    def break_up?
      force_break
    end

    def write_softline?
      break_up?
    end

    def indent_string(extra: 0)
      "  " * (indent_level + extra)
    end

    def write_child(child, indent_level: nil, group_level: nil, force_break: nil)
      indent_level ||= self.indent_level
      force_break ||= self.force_break

      self.class.new(
        child,
        indent_level: indent_level,
        max_length: max_length,
        force_break: force_break,
      ).to_s
    end
  end
end
