module Prettyrb
  module Formatters
    class If < Base
      def in_conditions?
        !!@in_conditions
      end

      def condition
        node.children[0]
      end

      def body
        node.children[1]
      end

      def else_node
        # The "else" when "elsifs" are present is always the last elsif's last child
        elsifs[-1].children[-1]
      end

      def format
        start = "#{indents}if "
        ending = "#{indents}end"

        if has_elsifs?
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
        else
          if else_body = node.children[2]
            else_body = Formatter.for(else_body).new(else_body, @indentation + 2, self).format

            "#{start}#{condition}\n#{body}\n#{indents}else\n#{else_body}\n#{ending}"
            [
              "#{indents}if #{subformatter(condition).skip_indentation_unless_multiline.format}",
              subformatter(body).format,
              "#{indents}else",
              else_body,
              "#{indents}end"
            ].join("\n")
          else
            [
              "#{indents}if #{subformatter(condition).skip_indentation_unless_multiline.format}",
              subformatter(body).format,
              "#{indents}end"
            ].join("\n")
          end
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
