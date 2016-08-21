require_relative 'test_helper'

class ObjectStructure < JsonProjectionTest
  parallelize_me!

  def test_simple_key_value_pair
    assert_equal [
      StartDocument.empty,
      StartObject.empty,
      Key.new("foo"),
      String.new("bar"),
      EndObject.empty,
      EndDocument.empty
    ], events("{\"foo\":\"bar\"}")
  end

  def test_key_value_pair_with_whitespace
    assert_equal [
      StartDocument.empty,
      StartObject.empty,
      Key.new("foo"),
      String.new("bar"),
      EndObject.empty,
      EndDocument.empty
    ], events("{ \"foo\" : \"bar\" }")
  end

  def test_multiple_key_value_pairs
    assert_equal [
      StartDocument.empty,
      StartObject.empty,
      Key.new("foo"),
      String.new("bar"),
      Key.new("qux"),
      String.new("quux"),
      EndObject.empty,
      EndDocument.empty
    ], events("{\"foo\": \"bar\", \"qux\": \"quux\"}")
  end

  def test_boolean_values
    assert_equal [
      StartDocument.empty,
      StartObject.empty,
      Key.new("foo"),
      Boolean.new(true),
      Key.new("bar"),
      Boolean.new(false),
      EndObject.empty,
      EndDocument.empty
    ], events("{\"foo\": true, \"qux\": false}")
  end
end
