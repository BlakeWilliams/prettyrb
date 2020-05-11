require "thor"

module Prettyrb
  class CLI < Thor
    desc "format [FILE]", "Ruby file to prettify"
    def print(file)
      content = File.read(file)
      formatted_content = Prettyrb::Formatter.new(content).format

      puts formatted_content
    end

    desc "write [FILES]", "Write prettified Ruby files"
    def write(*files)
      files.each do |file|
        content = File.read(file)
        formatted_content = Prettyrb::Formatter.new(content).format

        if options[:write]
          File.open(file, 'w') do |f|
            f.write(formatted_content)
          end
        else
          puts formatted_content
        end
      end
    end
  end
end
