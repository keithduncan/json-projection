require_relative '../test_helper'

class JsonParserTest < Minitest::Test
  include JsonProjection

  parallelize_me!

  def stream(string)
    StringIO.new(string)
  end

  def events(string)
    read_event_stream(stream(string))
  end

  def read_event_stream(io)
    parser = Parser.new(io)

    events = []

    while events.last != EndDocument.empty
      events << parser.next_event
    end

    events
  end

end
