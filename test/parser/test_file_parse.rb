require_relative 'test_helper'

require 'ruby-prof'

class ParseFileTest < JsonParserTest

  def test_parse_file
    file_path = ENV['JSON_FILE']
    if file_path.nil? || file_path.empty?
      return
    end

    file = File.open(file_path, 'r')

    begin
      result = RubyProf.profile do
        Parser.new(file).each { |e|
          #puts e
        }
      end

      # print a graph profile to text
      printer = RubyProf::CallStackPrinter.new(result)
      File.open('tmp/profile.html', 'w') do |f|
        printer.print(f, {})
      end
    ensure
      file.close
    end
  end

end
