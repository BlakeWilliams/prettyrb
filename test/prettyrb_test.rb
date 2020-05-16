require "test_helper"

class PrettyrbTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Prettyrb::VERSION
  end

  def test_regex_options
    source = <<~RUBY
    /hello/i
    RUBY

    expected = <<~RUBY
    /hello/i
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_super
    source = <<~RUBY
    def foo
      super 1
    end
    RUBY

    expected = <<~RUBY
    def foo
      super(1)
    end
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_inheritance
    source = <<~RUBY
    class Foo < Bar
      def self.wat
        1 + 1
      end
    end
    RUBY
    expected = <<~RUBY
    class Foo < Bar
      def self.wat
        1 + 1
      end
    end
    RUBY

    assert_code_formatted(expected, source, skip_rstrip: true)
  end

  def test_heredoc_method_calls
    source = "<<~RUBY.strip.replace(/hello/, 'goodbye')\n  puts 'hello'\nRUBY"
    expected = "<<~RUBY.strip.replace(/hello/, \"goodbye\")\n  puts 'hello'\nRUBY"

    assert_code_formatted(expected, source)
  end

  def test_heredoc
    source = "<<~RUBY\n  puts 'hello'\nRUBY"
    expected = "<<~RUBY\n  puts 'hello'\nRUBY"

    assert_code_formatted(expected, source)
  end

  def test_ensure
    source = <<~RUBY
    begin
      false
    ensure
      true
    end
    RUBY

    expected = <<~RUBY
    begin
      false
    ensure
      true
    end
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_begin
    source = <<~RUBY
    begin
      false
    end
    RUBY

    expected = <<~RUBY
    begin
      false
    end
    RUBY

    assert_code_formatted(expected, source)
  end


  def test_begin_rescue
    source = <<~RUBY
    begin
      false
    rescue Exception => e
      true
    end
    RUBY

    expected = <<~RUBY
    begin
      false
    rescue Exception => e
      true
    end
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_nth_ref
    source = <<~RUBY
    $1
    RUBY

    expected = <<~RUBY
    $1
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_negation
    source = <<~RUBY
    -foo
    RUBY

    expected = <<~RUBY
    -foo
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_mass_assign_grouped
    source = <<~RUBY
    a, b, (c, d) = [1, 2, [3, 4]]
    RUBY

    expected = <<~RUBY
    a, b, (c, d) = [1, 2, [3, 4]]
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_mass_assign
    source = <<~RUBY
    a, b, c = [1, 2]
    RUBY

    expected = <<~RUBY
    a, b, c = [1, 2]
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_block_arg
    source = <<~RUBY
    [1,2,3].map(&:ord)
    RUBY

    expected = <<~RUBY
    [1, 2, 3].map(&:ord)
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_const_cbase
    source = <<~RUBY
    require "file"
    ::File.new
    RUBY

    expected = <<~RUBY
    require("file")
    ::File.new
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_elsif
    source = <<~RUBY
      if a.present?
        true
      elsif a.values[0] == 2
        puts 1
        false
      elsif b.values[0] == 3
        puts 2
        false
      else
        nil
      end
    RUBY

    expected = <<~RUBY
      if a.present?
        true
      elsif a.values[0] == 2
        puts(1)
        false
      elsif b.values[0] == 3
        puts(2)
        false
      else
        nil
      end
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_kw_splat
    source = <<~RUBY
    b = {}
    { a: 1, **b }
    RUBY

    expected = <<~RUBY
    b = {}
    { a: 1, **b }
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_long_hash
    source = <<~RUBY
    { foo: 1, foo: 1, foo: 1, foo: 1, foo: 1, foo: 1, foo: 1, foo: 1, foo: 1, foo: 1, foo: 1, foo: 1, foo: 1, foo: 1, foo: 1 }
    RUBY

    expected = <<~RUBY
    {
      foo: 1,
      foo: 1,
      foo: 1,
      foo: 1,
      foo: 1,
      foo: 1,
      foo: 1,
      foo: 1,
      foo: 1,
      foo: 1,
      foo: 1,
      foo: 1,
      foo: 1,
      foo: 1,
      foo: 1,
    }
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_long_function_call_array
    source = <<~RUBY
    add [:value, :value, :value, :value, :value, :value, :value, :value, :value, :value, :value, :value, :value, :value, :value]
    RUBY

    expected = <<~RUBY
    add(
      [
        :value,
        :value,
        :value,
        :value,
        :value,
        :value,
        :value,
        :value,
        :value,
        :value,
        :value,
        :value,
        :value,
        :value,
        :value,
      ],
    )
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_long_function_call
    source = <<~RUBY
    add :value, :value, :value, :value, :value, :value, :value, :value, :value, :value, :value, :value, :value, :value, :value
    RUBY

    expected = <<~RUBY
    add(
      :value,
      :value,
      :value,
      :value,
      :value,
      :value,
      :value,
      :value,
      :value,
      :value,
      :value,
      :value,
      :value,
      :value,
      :value,
    )
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_long_multi_when
    source = <<~RUBY
    a = 1
    case a
    when :hello, :hello, :hello, :hello, :hello, :hello, :hello, :hello, :hello, :hello, :hello, :hello, :hello, :hello, :hello
      puts "hello"
    end
    RUBY

    expected = <<~RUBY
    a = 1
    case a
    when
      :hello,
      :hello,
      :hello,
      :hello,
      :hello,
      :hello,
      :hello,
      :hello,
      :hello,
      :hello,
      :hello,
      :hello,
      :hello,
      :hello,
      :hello
      puts("hello")
    end
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_multi_when
    source = <<~RUBY
    a = 1
    case a
    when 1, 2
      puts "hello"
    end
    RUBY

    expected = <<~RUBY
    a = 1
    case a
    when 1, 2
      puts("hello")
    end
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_unless
    source = <<~RUBY
    puts 'hello' unless false
    RUBY

    expected = <<~RUBY
    unless false
      puts("hello")
    end
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_and_asgn
    source = <<~RUBY
    a &&= 1
    RUBY

    expected = <<~RUBY
    a &&= 1
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_defined
    source = <<~RUBY
    defined?(a)
    RUBY

    expected = <<~RUBY
    defined?(a)
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_splat
    source = <<~RUBY
    a =  *c
    RUBY

    expected = <<~RUBY
    a = *c
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_hash_symbol
    source = <<~RUBY
    {rad: 1}
    RUBY

    expected = <<~RUBY
    { rad: 1 }
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_hash_rocket
    source = <<~RUBY
    {:rad =>1, "radder" =>2}
    RUBY

    expected = <<~RUBY
    { rad: 1, "radder" => 2 }
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_sclass
    source = <<~RUBY
    a = 1

    class << a
      puts "foo"
    end
    RUBY

    expected = <<~RUBY
    a = 1
    class << a
      puts("foo")
    end
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_defs
    source = <<~RUBY
    class Hello
      def self.wow
      end
    end
    RUBY

    expected = <<~RUBY
    class Hello
      def self.wow
      end
    end
    RUBY

    assert_code_formatted(expected, source, skip_rstrip: true)
  end

  def test_undef
    source = <<~RUBY
    undef :foo, :bar, :baz
    RUBY

    expected = <<~RUBY
    undef :foo, :bar, :baz
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_alias
    source = <<~RUBY
    alias shout puts
    RUBY

    expected = <<~RUBY
    alias :shout :puts
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_hash_kw
    source = <<~RUBY
      def foo(** rest)
      end
    RUBY

    expected = <<~RUBY
      def foo(**rest)
      end
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_restarg
    source = <<~RUBY
      def foo(* rest)
      end
    RUBY

    expected = <<~RUBY
      def foo(*rest)
      end
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_optarg
    source = <<~RUBY
      def foo(bar=1)
      end
    RUBY

    expected = <<~RUBY
      def foo(bar = 1)
      end
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_kwarg
    source = <<~RUBY
      def foo(bar:, baz:)
      end
    RUBY

    expected = <<~RUBY
      def foo(bar:, baz:)
      end
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_kw_opt_arg
    source = <<~RUBY
      def foo(bar: 1)
      end
    RUBY

    expected = <<~RUBY
      def foo(bar: 1)
      end
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_kw_rest_arg
    source = <<~RUBY
      def foo(**)
      end
    RUBY

    expected = <<~RUBY
      def foo(**)
      end
    RUBY

    assert_code_formatted(expected, source)
  end

  if RUBY_VERSION.to_f >= 2.7
    def test_forward_args
      source = <<~RUBY
      def foo(...)
        bar(...)
      end
      RUBY

      expected = <<~RUBY
      def foo(...)
        bar(...)
      end
      RUBY

      assert_code_formatted(expected, source)
    end

    def test_nil_keyword_arg
      source = <<~RUBY
      def foo(**nil)
      end
      RUBY

      expected = <<~RUBY
      def foo(**nil)
      end
      RUBY

      assert_code_formatted(expected, source)
    end
  end

  def test_adds_newlines_to_class
    source = <<~RUBY
    require 'foo'
    require 'bar'

    class Foo
      FOO = 1
      BAR = 2

      def hello
        a = 1
        b = 2

        if a != b
          1
        end
      end
    end
    RUBY
    result = Prettyrb::Formatter.new(source).format

    expected = <<~RUBY
    require("foo")
    require("bar")

    class Foo
      FOO = 1
      BAR = 2

      def hello
        a = 1
        b = 2

        if a != b
          1
        end
      end
    end
    RUBY

    assert_equal expected.rstrip, result.rstrip
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
