require "test_helper"

module Prettyrb
  class DocumentTest < Minitest::Test
    def test_groups_returns_all_nested_groups
      nested_group = Document::Group.new("foo")
      first_group = Document::Group.new("foo", nested_group)
      second_group = Document::Group.new("bar")

      builder = Document::Concat.new(
        first_group,
        second_group,
      )

      assert_equal [first_group, second_group, nested_group], builder.groups
    end

    def test_max_group_depth_returns_nested_count
      builder = Document::Concat.new(
        Document::Group.new(
          Document::Group.new(
            Document::Group.new(
            )
          )
        ),
        Document::Group.new(
          Document::Group.new(
          )
        )
      )

      assert_equal 3, builder.max_group_depth
    end
  end
end
