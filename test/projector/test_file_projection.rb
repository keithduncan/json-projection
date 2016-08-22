require_relative 'test_helper'

require 'ruby-prof'

class ProjectFile < JsonProjectorTest

  def test_project_file
    schema = {
      "forced" => nil,
      "created" => nil,
      "pusher" => {
        "name" => nil,
      },
      "repository" => {
        "name" => nil,
        "full_name" => nil,
      },
      "ref" => nil,
      "compare" => nil,
      "commits" => {
        "discinct" => nil,
        "message" => nil,
        "url" => nil,
        "id" => nil,
        "author" => {
          "username" => nil,
        }
      }
    }

    file_path = ENV['JSON_FILE']
    if file_path.nil? || file_path.empty?
      return
    end

    file = File.open(file_path, 'r')

    begin
      result = RubyProf.profile do
        project(schema, stream: file)
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
