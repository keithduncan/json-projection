module JsonProjection

  # Sum type
  class StreamEvent
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
  end

  class Value < StreamEvent
    attr_reader :value
    def initialize(value)
      @value = value
    end
  end

  class String < Value
  end

  class Number < Value
  end

  class Boolean < Value
  end

  class Null < StreamEvent
  end

end
