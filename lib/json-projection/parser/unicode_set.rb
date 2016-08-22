module JsonProjection
  class UnicodeSet
    def initialize(*vals)
      @vals = vals
    end

    def ===(val)
      val.each_codepoint { |c|
        return false unless @vals.include?(c)
      }
      true
    end
  end
end
