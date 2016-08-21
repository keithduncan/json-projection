require 'minitest/autorun'
require 'minitest/focus4'

require 'json-projection'

require 'stringio'
require 'byebug'

class JsonProjectionTopLevelTest < MiniTest::Unit::TestCase
  include JsonProjection

  def test_top_level_object
    events = read_event_stream(StringIO.new("{}"))
    assert_equal [StartDocument.empty, StartObject.empty, EndObject.empty, EndDocument.empty], events
  end

  def test_top_level_array
    events = read_event_stream(StringIO.new("[]"))
    assert_equal [StartDocument.empty, StartArray.empty, EndArray.empty, EndDocument.empty], events
  end

  private

  def read_event_stream(io)
    parser = Parser.new(io)

    events = []

    while events.last != EndDocument.empty
      events << parser.next_event
    end

    events
  end
end
