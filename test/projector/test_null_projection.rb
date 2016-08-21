require_relative 'test_helper'

class NullProjection < JsonProjectorTest

  def test_null_object_projection
    projector = JsonProjection::Projector.new(stream("{\"foo\": \"bar\"}"))
    assert_equal({"foo" => "bar"}, projector.project(nil))
  end

  def test_empty_object_projection
    projector = JsonProjection::Projector.new(stream("{\"foo\": \"bar\"}"))
    assert_equal({}, projector.project({}))
  end

  def test_filtering_object_projection
    projector = JsonProjection::Projector.new(stream("{\"foo\": \"bar\", \"qux\": \"quux\"}"))
    assert_equal({"foo" => "bar"}, projector.project({"foo" => nil}))
  end

end
