module Prettyrb
  module Formatters
    class If < Base
      def format
        if has_elsifs?
          format_if_with_elsifs
        else
          if else_node
            format_if_with_else
          else
            format_if
          end
        end
      end

      private

      def format_if
        [
          "#{indents}if #{subformatter(condition).skip_indentation_unless_multiline.format}",
          subformatter(body).format,
          "#{indents}end"
        ].join("\n")
      end

      def format_if_with_else
        [
          "#{indents}if #{subformatter(condition).skip_indentation_unless_multiline.format}",
          subformatter(body).format,
          "#{indents}else",
          subformatter(else_node).format,
          "#{indents}end"
        ].join("\n")
      end

      def format_if_with_elsifs
        extra_conditions = elsifs.map do |elsif_node|
          ElsifFormatter.new(elsif_node, indentation, self).format
        end

        if else_node
          else_body = Formatter.for(else_node).new(else_node, indentation + 2, self).format
          [
            "#{indents}if #{subformatter(condition).skip_indentation_unless_multiline.format}",
            subformatter(body).format,
            extra_conditions.join("\n"),
            "#{indents}else",
            subformatter(else_node).format,
            "#{indents}end"
          ].join("\n")
        else
          [
            "#{indents}if #{subformatter(condition).skip_indentation_unless_multiline.format}",
            subformatter(body).format,
            extra_conditions.join("\n"),
            "#{indents}end"
          ].join("\n")
        end
      end

      def condition
        node.children[0]
      end

      def body
        node.children[1]
      end

      def else_node
        if has_elsifs?
          # The "else" when "elsifs" are present is always the last elsif's last child
          elsifs[-1].children[-1]
        else
          node.children[2]
        end
      end

      def has_elsifs?
        elsifs.length != 0
      end

      def elsifs
        return [] if !node.children[2] || node.children[2].type != :if
        return [] if node.children[1].type == :if # maybe remove?

        @_elsifs ||= find_elsifs(node.children[2], [])
      end

      def find_elsifs(node, elsifs)
        if node.type == :if && node.children[1].type != :if && (node.children[2] && node.children[2].type == :if)
          find_elsifs(node.children[2], elsifs + [node])
        elsif elsifs.length == 0
          []
        else
          elsifs + [node]
        end
      end
    end

    class ElsifFormatter < Base
      def in_conditions?
        !!@in_conditions
      end

      def format
        if node.type != :if
          raise "Something wrong with #{node}. Not an if"
        end
        children = node.children

        @in_conditions = true
        condition = Formatter.for(children[0]).new(children[0], indentation + 2, self).format
        @in_conditions = false

        body = Formatter.for(children[1]).new(children[1], indentation + 2, self).format
        "#{indents}elsif #{condition}\n#{body}"
      end
    end
  end
end
