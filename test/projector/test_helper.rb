require_relative '../test_helper'

require 'json'

class JsonProjectorTest < Minitest::Test
  include JsonProjection

  parallelize_me!

  def project(schema, over: "", json: nil, stream: nil)
    if stream.nil?
      if json.nil?
        json = over.to_json
      end

      stream = StringIO.new(json)
    end

    Projector.new(stream).project(schema)
  end

end
