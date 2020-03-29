require "test_helper"

class PrettyrbTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Prettyrb::VERSION
  end

  def test_breaks_up_long_conditionals
    source = <<~RUBY
    if "hello" != "foo bar baz" && "foo" != "hello world" && "wow" != "okay this might be long" && "wow this is really really long" != "okay"
      true
    end
    RUBY
    result = Prettyrb::Formatter.new(source).format

    expected = <<~RUBY
    if
      "hello" != "foo bar baz" &&
      "foo" != "hello world" &&
      "wow" != "okay this might be long" &&
      "wow this is really really long" != "okay"
    then
      true
    end
    RUBY

    assert_equal expected.rstrip, result.rstrip
  end

  def test_supports_booleans
    source = <<~RUBY
    if 1
      true
    else
      false
    end
    RUBY
    result = Prettyrb::Formatter.new(source).format

    expected = <<~RUBY
    if 1
      true
    else
      false
    end
    RUBY

    assert_equal expected.strip, result
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
    if (1 && 2) || 1 != 2
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

    assert_equal expected, result
  end

  def test_array_assign
    source = <<~RUBY
    hello = ["really really really really really really really really really long", "really really really really really really really really really long"]
    RUBY

    expected = <<~RUBY
    hello = [
      "really really really really really really really really really long",
      "really really really really really really really really really long",
    ]
    RUBY
    result = Prettyrb::Formatter.new(source).format

    assert_equal expected.rstrip, result
  end

  def test_array_assign_with_join
    source = <<~RUBY
    def rad
      hello = ["really really really really really really really really really long", "really really really really really really really really really long"].join(",")
    end
    RUBY

    expected = <<~RUBY
    def rad
      hello = [
        "really really really really really really really really really long",
        "really really really really really really really really really long",
      ].join(",")
    end
    RUBY
    result = Prettyrb::Formatter.new(source).format

    assert_equal expected.rstrip, result
  end
end
