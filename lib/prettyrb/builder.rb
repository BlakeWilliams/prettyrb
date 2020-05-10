module Prettyrb
  class Builder < Parser::Builders::Default
    NODE_TYPES = {
      if: Prettyrb::Nodes::IfNode,
      str: Prettyrb::Nodes::StrNode,
      dstr: Prettyrb::Nodes::DstrNode,
    }.freeze

    def n(type, children, source_map)
      node_class = NODE_TYPES.fetch(type, Prettyrb::Nodes::BaseNode)

      node_class.new(type, children, location: source_map)
    end
  end
end
