require "thor"

module Prettyrb
  class CLI < Thor
    desc "format [FILE]", "Ruby file to prettify"
    option :write, type: :boolean
    method_option :files, type: :array
    def format(*files)
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
