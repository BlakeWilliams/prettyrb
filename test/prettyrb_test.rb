require "test_helper"

class PrettyrbTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Prettyrb::VERSION
  end

  def test_formats_basic_statement
    source = <<~RUBY
    if 1
    'hello'
    end
    RUBY
    result = Prettyrb::Formatter.new(source).format

    expected = <<~RUBY
    if 1
      "hello"
    end
    RUBY

    assert_equal expected.strip, result
  end

  def test_formats_conditionals
    source = <<~RUBY
    if (1&&2) ||
    (1!=2)
      'hello'
    end
    RUBY
    result = Prettyrb::Formatter.new(source).format

    expected = <<~RUBY
    if (1 && 2) || (1 != 2)
      "hello"
    end
    RUBY

    assert_equal expected.strip, result
  end

  def test_basic_class
    source = <<~RUBY
    class Foo
      DATA = ["hello", "world"].freeze
    end
    RUBY

    expected = <<~RUBY
    class Foo
      DATA = ["hello", "world"].freeze
    end
    RUBY
    result = Prettyrb::Formatter.new(source).format

    assert_equal expected.strip, result
  end
end
