module Prettyrb
  module Formatters
    class True < Base
      def format
        "#{indents}true"
      end
    end
  end
end
