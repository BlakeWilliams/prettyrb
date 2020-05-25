require "test_helper"

module Prettyrb
  class WriterTest < Minitest::Test
    include Document::DSL

    def test_concat_appends_values
      builder = Document::Concat.new("foo", "bar")
      assert_equal "foobar", Writer.new(builder).to_s
    end

    def test_indent_increases_indentation_for_newlines
      builder = Document::Indent.new(Document::Hardline.new, "foo")
      assert_equal "\n  foo", Writer.new(builder).to_s
    end
    
    def test_dedent_decreases_indentation_for_newlines
      builder = Document::Indent.new(
        Document::Hardline.new,
        "foo",
        Document::Dedent.new(
          Document::Hardline.new,
          "bar",
        )
      )
      assert_equal "\n  foo\nbar", Writer.new(builder).to_s
    end

    def test_group_breaks_up_outer_first
      builder = concat(
        group(
          "really",
          softline,
          "long",
          softline,
          "line",
          softline,
          group(
            "a",
            softline,
            "b",
          )
        )
      )

      assert_equal "really\nlong\nline\nab", Writer.new(builder, max_length: 10).to_s
    end

    def test_group_breaks_up_inner_if_outer_fits
      builder = concat(
        group(
          "a",
          softline,
          "b",
          group(
            softline,
            "really",
            softline,
            "long",
            softline,
            "line",
          )
        )
      )

      assert_equal "ab\nreally\nlong\nline", Writer.new(builder, max_length: 10).to_s
    end

    def test_group_breaks_both_groups_if_both_fit_when_broken
      builder = group(
        "really",
        softline,
        "long",
        softline,
        "line",
        softline,
        group(
          "really",
          softline,
          "long",
          softline,
          "line",
        )
      )

      assert_equal "really\nlong\nline\nreally\nlong\nline", Writer.new(builder, max_length: 10).to_s
    end

    def test_group_handles_when_no_breaks_fit
      builder = concat(
        group(
          "really",
          "long",
          "line",
          softline,
          group(
            "really",
            "long",
            "line",
          )
        )
      )

      assert_equal "reallylongline\nreallylongline", Writer.new(builder, max_length: 10).to_s
    end
  end
end
