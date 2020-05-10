
module Prettyrb
  module Nodes
    class StrNode < BaseNode
      HEREDOC_TYPE_REGEX = /<<(.)?/

      def heredoc_identifier
        loc.heredoc_end.source
      end

      def heredoc_type
        # Always use indentable ending heredoc type if no type was provided
        #
        # eg: <<RUBY becomes <<-RUBY since <<- allows the ending identifier
        # to be indented
        loc.expression.source.match(HEREDOC_TYPE_REGEX)[1] || "-"
      end

      def heredoc_body
        loc.heredoc_body.source
      end

      def heredoc?
        !!loc.respond_to?(:heredoc_body)
      end

      def format
        raw_content = loc.expression.source
        content = raw_content[1...-1]

        if raw_content[0] == "'"
          content.gsub('"', '\\"').gsub('#{', '\\#{')
        else
          content.gsub("\\", "\\\\")
        end
      end
    end
  end
end
