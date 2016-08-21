require_relative '../test_helper'

class JsonProjectorTest < MiniTest::Unit::TestCase

  def stream(str)
    StreamIO.new(str)
  end

end
