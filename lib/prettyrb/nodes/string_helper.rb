module Prettyrb
  module Nodes
    module StringHelper
      HEREDOC_TYPE_REGEX = /<<([~-])?/

      def percent_string?
        loc.expression.source.start_with?("%")
      end

      def percent_character
        loc.expression.source[1]
      end

      def start_delimiter
        loc.expression.source[2]
      end

      def closing_delimiter
        loc.expression.source.rstrip[-1]
      end

      def heredoc_identifier
        loc.heredoc_end.source.strip
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
    end
  end
end
