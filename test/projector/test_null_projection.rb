require_relative 'test_helper'

class NullProjection < JsonProjectorTest
  def test_null_object_projection
    json = {
      "foo" => "bar",
    }

    assert_equal({
      "foo" => "bar"
    }, project(nil, over: json))
  end

  def test_empty_object_projection
    json = {
      "foo" => "bar",
    }
    assert_equal({}, project({}, over: json))
  end

  def test_filtering_object_projection
    json = {
      "foo" => "bar",
      "qux" => "quux",
    }

    schema = {
      "foo" => nil,
    }

    assert_equal({
      "foo" => "bar"
    }, project(schema, over: json))
  end
end
