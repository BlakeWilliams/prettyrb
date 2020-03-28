module Prettyrb
  module Formatters
    class If < Base
      def in_conditions?
        !!@in_conditions
      end

      def format
        condition, body = node.children[0..1]
        start = "#{indents}if "
        ending = "#{indents}end"

        body = Formatter.for(body).new(body, indentation + 2, self).format

        @in_conditions = true
        condition = Formatter.for(condition).new(condition, indentation + 2, self).format
        @in_conditions = false

        if has_elsifs?
          extra_conditions = elsifs.map do |elsif_node|
            if elsif_node.type != :if
              raise "Something wrong with #{elsif_node}. Not an if"
            end
            children = elsif_node.children

            @in_conditions = true
            elsif_condition = Formatter.for(children[0]).new(children[0], indentation + 2, self).format
            @in_conditions = false

            elsif_body = Formatter.for(children[1]).new(children[1], indentation + 2, self).format
            "#{indents}elsif #{elsif_condition}\n#{elsif_body}"
          end

          else_node = elsifs[-1].children[-1]
          if else_node
            else_body = Formatter.for(else_node).new(else_node, indentation + 2, self).format
            "#{start}#{condition}\n#{body}\n#{extra_conditions.join("\n")}\n#{indents}else\n#{else_body}\n#{ending}"
          else
            "#{start}#{condition}\n#{body}\n#{extra_conditions.join("\n")}\n#{ending}"
          end
        else
          if else_body = node.children[2]
            else_body = Formatter.for(else_body).new(else_body, @indentation + 2, self).format
            "#{start}#{condition}\n#{body}\n#{indents}else\n#{else_body}\n#{ending}"
          else
            "#{start}#{condition}\n#{body}\n#{ending}"
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
  end
end
