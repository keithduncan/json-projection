module JsonProjection
  class Fifo

    def self.empty
      @empty ||= self.new([].freeze)
    end

    def self.pure(*vals)
      Fifo.new(vals)
    end

    def initialize(stack = [])
      @stack = stack
    end

    def push!(val)
      @stack.insert(0, val)
    end

    def pop!
      @stack.pop
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

    def prepend!(fifo)
      return if fifo.empty?
      if empty?
        @stack = fifo.stack.dup
        return
      end
      @stack = fifo.stack.concat(@stack)
    end

    protected

    def stack
      @stack
    end

  end
end
