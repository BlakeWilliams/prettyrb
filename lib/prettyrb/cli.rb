require "thor"

module Prettyrb
  class CLI < Thor
    desc "format FILE", "file to prettify"
    def format(file)
      content = File.read(file)
      puts Prettyrb::Formatter.new(content).format
    end
  end
end
