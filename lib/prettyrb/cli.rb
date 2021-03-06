require "thor"

module Prettyrb
  class CLI < Thor
    desc "format [FILE]", "Ruby file to prettify"
    def format(file)
      content = File.read(file)
      formatted_content = Prettyrb::Formatter.new(content).format

      puts formatted_content
    end

    desc "write [FILES]", "Write prettified Ruby files"
    def write(*files)
      files.each do |file|
        content = File.read(file)
        begin
          formatted_content = Prettyrb::Formatter.new(content).format
        rescue Exception => e
          puts "Failed to write #{file}"
          throw e
        end

        File.open(file, 'w') do |f|
          f.write(formatted_content)
        end
      end
    end
  end
end
