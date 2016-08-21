require_relative 'events'
require_relative 'errors'

module JsonProject
  # Pull based event scanner.
  class Scanner

    # Initialize a new scanner with a stream. The cursor is advanced as events
    # are drawn from the scanner.
    #
    # stream :: IO
    #           IO stream to read data from.
    #
    # Returns nothing.
    def initialize(steam)
      @stream = stream
      @buffer = nil
    end

    # Draw bytes from the stream until an event can be constructed. May raise
    # IO errors.
    #
    # Returns a JsonProject::StreamEvent subclass or raises StandardError.
    def next_event()

    end

    # Advance the stream cursor until after the given event class. This method
    # considers Object and Array nesting, use it to skip a subset of the input
    # document stream.
    #
    # If the document is malformed and EOF is reached before the terminating
    # event, JsonProject::ParseError is raised.
    #
    # Returns nothing, may raise StandardError.
    def read_until(klass)

    end

  end
end
