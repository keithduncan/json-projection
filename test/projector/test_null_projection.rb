require_relative 'test_helper'

class TopLevelTest < JsonProjectorTest

  def test_empty_object_projection
    projector = JsonProjection::Projector(stream("{}"))
    assert_equal {}, projector.project(nil)
  end

end
