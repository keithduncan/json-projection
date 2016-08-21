require_relative '../test_helper'

require 'json'

class JsonProjectorTest < Minitest::Test
  include JsonProjection

  parallelize_me!

  def stream(str)
    StringIO.new(str)
  end

  def project(schema, over: "", json: nil)
    if json == nil
      json = over.to_json
    end

    Projector.new(stream(json)).project(schema)
  end

end
