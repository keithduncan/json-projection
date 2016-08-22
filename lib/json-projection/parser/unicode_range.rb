module JsonProjection
  class UnicodeRange
    def initialize(start, en)
      @range = Range.new(start, en)
    end

    def ===(val)
      val.each_codepoint { |c|
        return false unless @range.include?(c)
      }
      true
    end
  end
end
