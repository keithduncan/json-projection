module JsonProjection
  class Fifo

    attr_reader :stack

    def initialize
      @stack = []
    end

    def push(val)
      @stack.insert(0, val)
    end

    def pop()
      @stack.pop
    end

    def concat(fifo)
      Fifo.new(@stack.concat(fifo.stack))
    end
  end
end
