require_relative '../test_helper'

require 'ruby-prof'

class ParseFileTest < Minitest::Test

  include JsonProjection

  def test_parse_file
    file_path = ENV['JSON_FILE']
    if file_path.nil? || file_path.empty?
      return
    end

    file = File.open(file_path, 'r')

    begin
      result = RubyProf.profile do
        parser = Parser.new(file)

        counter = 1_000
        loop do
          counter -= 1
          break if counter == 0
          puts counter

          event = parser.next_event
          puts event.class
          break if event.is_a?(EndDocument)
        end
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
