require 'minitest/autorun'
require 'minitest/focus4'

require 'json-projection'

require 'stringio'
require 'byebug'

class JsonProjectionTopLevelTest < MiniTest::Unit::TestCase
  focus
  def test_top_level_object
    events = read_event_stream(StringIO.new("{}"))
    assert_equal [JsonProjection::StartDocument.new, JsonProjection::StartObject.new, JsonProjection::EndObject.new, JsonProjection::EndDocument.new], events
  end

  def test_top_level_array
    events = read_event_stream(StringIO.new("[]"))
    assert_equal [JsonProjection::StartDocument.new, JsonProjection::StartArray.new, JsonProjection::EndArray.new, JsonProjection::EndDocument.new], events
  end

  private

  def read_event_stream(io)
    parser = JsonProjection::Parser.new(io)

    events = []

    while events.last != JsonProjection::EndDocument.new
      events << parser.next_event
    end

    events
  end
end
