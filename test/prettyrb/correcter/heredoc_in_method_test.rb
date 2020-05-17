require "test_helper"

class PrettyrbTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Prettyrb::VERSION
  end

  def test_heredoc_with_interpolation
    source = <<~RUBY
      puts <<~OKAY.strip
        hello \#{name}
      OKAY
    RUBY

    expected = <<~RUBY
      puts(<<~OKAY.strip)
        hello \#{name}
      OKAY
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_heredoc_with_method_calls
    source = <<~RUBY
      puts <<OKAY.strip, <<RAD.replace("foo", "bar")
        cool
      OKAY
        very rad
      RAD
    RUBY

    expected = <<~RUBY
      puts(<<-OKAY.strip, <<-RAD.replace("foo", "bar"))
        cool
      OKAY
        very rad
      RAD
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_multiline_heredoc
    source = <<~RUBY
      puts "hello", "goodbye", <<RAD, "awesome", "dope", "okay", "more args", "even more args", "wow, even more args!!!", <<~OKAY
        very rad
      RAD
        wat
      OKAY
    RUBY

    expected = <<~RUBY
      puts(
        "hello",
        "goodbye",
        <<-RAD,
        "awesome",
        "dope",
        "okay",
        "more args",
        "even more args",
        "wow, even more args!!!",
        <<~OKAY,
      )
        very rad
      RAD
        wat
      OKAY
    RUBY

    assert_code_formatted(expected, source)
  end

  def test_heredoc
    source = <<~RUBY
      puts <<OKAY, <<RAD
        cool
      OKAY
        very rad
      RAD
    RUBY

    expected = <<~RUBY
      puts(<<-OKAY, <<-RAD)
        cool
      OKAY
        very rad
      RAD
    RUBY

    assert_code_formatted(expected, source)
  end
end
