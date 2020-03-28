require "test_helper"

module Prettyrb
  module Formatters
    class IfTest < Minitest::Test
      def test_basic_if
        basic_if = parse_source <<~RUBY
        if 1
          true
        else
          false
        end
        RUBY
        formatter = If.new(basic_if, 2, nil)

        expected = <<-RUBY.rstrip
  if 1
    true
  else
    false
  end
        RUBY

        assert_equal expected, formatter.format
      end

      def test_elsif_as_else
        basic_if = parse_source <<~RUBY
        if 1
          true
        elsif 2
          false
        end
        RUBY
        formatter = If.new(basic_if, 2, nil)

        expected = <<-RUBY.rstrip
  if 1
    true
  else
    if 2
      false
    end
  end
        RUBY

        assert_equal expected, formatter.format
      end

      def test_elsif_with_else
        basic_if = parse_source <<~RUBY
        if 1
          'a'
        elsif 2
          'b'
        elsif 3
          'c'
        else
          'n/a'
        end
        RUBY
        formatter = If.new(basic_if, 2, nil)

        expected = <<-RUBY.rstrip
  if 1
    "a"
  elsif 2
    "b"
  elsif 3
    "c"
  else
    "n/a"
  end
        RUBY

        assert_equal expected, formatter.format
      end
    end
  end
end
