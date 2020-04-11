module Prettyrb
  class Builder < Parser::Builders::Default
    def n(type, children, source_map)
      Prettyrb::Node.new(type, children, :location => source_map)
    end
  end
end
