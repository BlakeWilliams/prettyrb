# Prettyrb

Super experimental gem for auto-formatting Ruby files. AKA the code isn't great, but things are kind of working.

Pronounced "pretty-erb".

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'prettyrb'
```

And then execute:

    $ bundle

Or install it globally:

    $ gem install prettyrb

## Usage

CLI:

```
$ prettyrb format FILE
```

or to re-write the file:

```
prettyrb write FILE
```

In Ruby code:

```ruby
PrettyRb.new(source_code).format
```

## Does it work?

- [x] Formats self and tests still pass
- [ ] Formats `rais/rails` and tests still pass
- [ ] Keeps comments

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
