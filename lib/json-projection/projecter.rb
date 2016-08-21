require_relative 'parser'

module JsonProjection
  class Projector

    # Initialize a new projector with a stream. The stream is consumed until the
    # JSON structure it contains is finished.
    #
    # stream :: IO
    #           IO stream to read data from.
    #
    # Returns nothing.
    def initialize(stream)
      @parser = Parser.new(stream)
    end

  end
end
