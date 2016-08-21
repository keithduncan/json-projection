require 'minitest/autorun'
require 'json-projection'

class JsonProjectionTopLevelTest < MiniTest::Unit::TestCase
  def test_top_level_object
    events = read_event_stream(StringIO.new("{}"))
    assert_equal [JsonProjection::StartDocument, JsonProjection::StartObject, JsonProjection::EndObject, JsonProjection::EndDocument], events
  end

  def test_top_level_array
    events = read_event_stream(StringIO.new("[]"))
    assert_equal [JsonProjection::StartDocument, JsonProjection::StartArray, JsonProjection::EndArray, JsonProjection::EndDocument], events
  end

  private

  def read_event_stream(io)
    parser = JsonProjection::Parser.new(io)

    events = []

    while events.last != JsonProjection::EndDocument
      events << parser.next_event
    end

    events
  end
end
