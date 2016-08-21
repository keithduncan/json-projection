require_relative 'test_helper'

class ArraySchema < JsonProjectorTest
  def test_array_schema
    json = {
      "users" => [
        {
          "name" => "keith",
          "company" => "internet plumbing inc",
          "department" => "janitorial",
        },
        {
          "name" => "justin",
          "company" => "big blue",
          "department" => "programming?",
        },
        {
          "name" => "alan",
          "company" => "different colour of blue",
          "department" => "drop bear containment",
        }
      ]
    }

    schema = {
      # /users is an array of objects, each having many keys we only want name
      "users" => {
        "name" => nil,
      }
    }

    assert_equal({
      "users" => [
        { "name" => "keith" },
        { "name" => "justin" },
        { "name" => "alan" }
      ]
    }, project(schema, over: json))
  end
end
