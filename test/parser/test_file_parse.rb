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
      Parser.new(file).each_event do |event|
        
      end
    ensure
      file.close
    end
  end

end
