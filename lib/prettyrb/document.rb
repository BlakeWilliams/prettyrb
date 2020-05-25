module Prettyrb
  module Document
    module DSL
      def concat(*args)
        Document::Concat.new(*args)
      end

      def join(*args)
        Document::Join.new(*args)
      end

      def group(*args)
        Document::Group.new(*args)
      end

      def if_break(*args)
        Document::IfBreak.new(*args)
      end

      def indent(*args)
        Document::Indent.new(*args)
      end

      def dedent(*args)
        Document::Dedent.new(*args)
      end

      def hardline(*args)
        Document::Hardline.new(*args)
      end

      def softline(*args)
        Document::Softline.new(*args)
      end
    end

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

      def has_group_part?
        parts.any? { |p| p.is_a?(Group) }
      end

      def groups
        parts.select { |p| p.is_a?(Group) } + parts.flat_map do |p|
          p.groups if p.respond_to?(:groups)
        end.compact
      end

      def max_group_depth
        return @max_group_depth if defined?(@max_group_depth)

        has_groups = parts.any? { |p| p.is_a?(Group) }

        total = if has_groups
          1
        else
          0
        end

        # TODO swap filter/flat_map for single iteration
        nested_total = parts.
          filter { |p| p.respond_to?(:max_group_depth) }.
          flat_map { |p| p.max_group_depth }.
          max

        @max_group_depth = total + (nested_total || 0)
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

    class Concat < Builder
    end

    class Group < Builder
      attr_reader :joiner

      def initialize(*args, joiner: "")
        super(*args)
        @joiner = joiner
      end
    end

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

    class Indent < Builder
      attr_reader :only_when_break

      def initialize(*args, only_when_break: false)
        @only_when_break = only_when_break
        super(*args)
      end
    end

    class Dedent < Builder
    end

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
  end
end
