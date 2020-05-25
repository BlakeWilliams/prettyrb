module Prettyrb
  module Document
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
