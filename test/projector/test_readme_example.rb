require_relative 'test_helper'

class ReadmeExample < JsonProjectorTest
  def test_readme_example
    json = <<EOJ
    {
      "user": {
        "name": "keith",
        "age": 26,
        "jobs": [
          {
            "title": "director of overworking",
            "company": "south coast software",
            "department": "most"
          },
          {
            "title": "some kind of computering",
            "company": "github the website dot com",
            "department": true
          }
        ]
      },
      "another key": {

      },
      "woah this document is huge": {

      },
      "many megabytes": {

      },
      "etc": {

      }
    }
EOJ

    schema = {
      "user" => {
        "name" => nil,
        "jobs" => {
          "title" => nil,
        },
      },
    }

    assert_equal({
      "user" => {
        "name" => "keith",
        "jobs" => [
          { "title" => "director of overworking" },
          { "title" => "some kind of computering" },
        ]
      }
    }, project(schema, over: json))
  end
end
