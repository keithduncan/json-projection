require 'minitest/autorun'
require 'minitest/focus4'

require 'json-projection'

require 'stringio'
require 'byebug'

class JsonProjectionTest < MiniTest::Unit::TestCase

  def stream(string)
    StringIO.new(string)
  end

  def events(string)
    read_event_stream(stream("{}"))
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
