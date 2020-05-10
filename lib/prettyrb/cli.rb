require "thor"

module Prettyrb
  class CLI < Thor
    desc "format FILE", "file to prettify"
    option :write, type: :boolean
    def format(file)
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
