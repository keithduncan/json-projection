require_relative '../test_helper'

class JsonProjectorTest < MiniTest::Unit::TestCase

  def stream(str)
    StringIO.new(str)
  end

end
