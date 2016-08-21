require_relative 'test_helper'

class NullProjection < JsonProjectorTest

  def test_empty_object_projection
    projector = JsonProjection::Projector.new(stream("{}"))
    assert_equal({}, projector.project(nil))
  end

end
