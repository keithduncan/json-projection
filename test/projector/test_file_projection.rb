require_relative 'test_helper'

require 'benchmark'
require "benchmark/memory"

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
        "distinct" => nil,
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

    Benchmark.memory { |x|
      x.report("project (pure ruby)") { project(schema, stream: File.open(file_path, 'r')) }
      x.compare!
    }
  end

end
