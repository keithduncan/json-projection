require_relative 'test_helper'

class TopLevelTest < JsonProjectionTest
  def test_top_level_object
    assert_equal [StartDocument.empty, StartObject.empty, EndObject.empty, EndDocument.empty], events("{}")
  end

  def test_top_level_array
    assert_equal [StartDocument.empty, StartArray.empty, EndArray.empty, EndDocument.empty], events("[]")
  end

end
