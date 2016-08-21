module JsonProjection

  # Sum type
  class StreamEvent

    def self.empty
      @empty ||= new
    end

    def ==(other)
      other.is_a?(self.class)
    end

    def hash
      self.class.hash
    end

  end

  class StartDocument < StreamEvent
  end

  class EndDocument < StreamEvent
  end

  class StartObject < StreamEvent
  end

  class EndObject < StreamEvent
  end

  class StartArray < StreamEvent
  end

  class EndArray < StreamEvent
  end

  class Key < StreamEvent
    attr_reader :key
    def initialize(key)
      @key = key
    end

    def ==(other)
      return false unless super(other)
      return key == other.key
    end

    def hash
      key.hash
    end
  end

  class Value < StreamEvent
    attr_reader :value
    def initialize(value)
      @value = value
    end

    def ==(other)
      return false unless super(other)
      return value == other.value
    end
  end

  class String < Value
  end

  class Number < Value
  end

  class Boolean < Value
  end

  class Null < Value
  end

end
