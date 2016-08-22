require_relative 'test_helper'

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

    data = begin
      project(schema, stream: file)
    ensure
      file.close
    end
  end

end
