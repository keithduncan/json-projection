require_relative '../test_helper'

require 'json'

class JsonProjectorTest < MiniTest::Unit::TestCase
  include JsonProjection

  parallelize_me!

  def stream(str)
    StringIO.new(str)
  end

  def project(schema, over: "")
    Projector.new(stream(over.to_json)).project(schema)
  end

end
