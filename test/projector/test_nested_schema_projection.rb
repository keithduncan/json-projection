require_relative 'test_helper'

class NestedProjection < JsonProjectorTest

  def test_nested_projection
    json = {
      "foo" => 42,

      "bar" => {
        "name" => "keith",
        "occupation" => "professional computering",
        "age" => 26,
        "hobbies" => [
          "not computering",
        ]
      },

      "qux" => {
        "quux" => [
          {
            "name" => "Reactive X",
            "members" => "many",
          },
          {
            "name" => "lstoll",
            "members" => "such",
          },
          {
            "name" => "github",
            "members" => "very",
          },
          {
            "name" => "theleague",
            "members" => "numerous",
          }
        ],

        "corge" => {
          "name" => "Brighton",
          "address" =>"Buckingham Road",
        },
      },

      "grault" => nil,

      "waldo" => true,
    }

    schema = {
      # include the /foo subtree (is a single number)
      "foo" => nil,

      # ignore the bar subtree (is an object)
      # "bar" => ???

      # include some of the /qux subtree (is an object)
      "qux" => {
        # include the whole /qux/quux subtree (is an array of objects)
        "quux" => nil,

        # include some of the /qux/corge subtree (is another object)
        "corge" => {
          # include name (is a string)
          "name" => nil,
          # include age (is missing from source doc)
          "age" => nil,
          # ignore address
          # "address" => ???
        },
      },

      # include the /grault subtree (is a null literal)
      "grault" => nil,

      # include the /waldo subtree (is a boolean literal)
      "waldo" => nil,
    }

    assert_equal({
      "foo" => 42,

      "qux" => {
        "quux" => [
          {
            "name" => "Reactive X",
            "members" => "many",
          },
          {
            "name" => "lstoll",
            "members" => "such",
          },
          {
            "name" => "github",
            "members" => "very",
          },
          {
            "name" => "theleague",
            "members" => "numerous",
          }
        ],

        "corge" => {
          "name" => "Brighton",
        },
      },

      "grault" => nil,

      "waldo" => true,
    }, project(schema, over: json))
  end

  def test_a_schema_that_expects_an_object_but_is_simple
    json = {
      # surprise! the json doesn't include an object under the foo key
      "foo" => 42,
    }

    schema = {
      # include some of the /foo subtree
      "foo" => {
        # include the whole /foo/baz subtree
        "baz" => nil,
      }
    }

    # expect the 42 to be pulled out
    assert_equal({
      "foo" => 42
    }, project(schema, over: json))
  end

end
