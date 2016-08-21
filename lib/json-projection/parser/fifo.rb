module JsonProjection
  class Fifo

    def self.empty
      @empty ||= self.new
    end

    def self.pure(val)
      Fifo.new([val])
    end

    def initialize(stack = [])
      @stack = stack
    end

    def push(val)
      Fifo.new(@stack.dup.insert(0, val))
    end

    def pop()
      return self, nil if empty?

      init = @stack.slice(0, @stack.size - 1)
      last = @stack.last

      return Fifo.new(init), last
    end

    def empty?
      @stack.empty?
    end

    def ==(other)
      return false unless other.is_a?(Fifo)
      return stack == other.stack
    end

    def hash
      stack.hash
    end

    def append(fifo)
      return self if fifo.empty?
      return fifo if self.empty?
      Fifo.new(@stack.concat(fifo.stack))
    end

    protected

    attr_reader :stack

  end
end
