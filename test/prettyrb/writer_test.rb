require "test_helper"

module Prettyrb
  class WriterTest < Minitest::Test
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
  end
end
