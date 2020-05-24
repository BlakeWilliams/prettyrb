module Prettyrb
  class Builder < Parser::Builders::Default
    NODE_TYPES = {
      and: Prettyrb::Nodes::AndNode,
      dstr: Prettyrb::Nodes::DstrNode,
      if: Prettyrb::Nodes::IfNode,
      or: Prettyrb::Nodes::OrNode,
      regexp: Prettyrb::Nodes::RegexpNode,
      send: Prettyrb::Nodes::SendNode,
      str: Prettyrb::Nodes::StrNode,
      def: Prettyrb::Nodes::DefNode,
    }.freeze

    def n(type, children, source_map)
      node_class = NODE_TYPES.fetch(type, Prettyrb::Nodes::BaseNode)

      node_class.new(type, children, location: source_map)
    end
  end
end
