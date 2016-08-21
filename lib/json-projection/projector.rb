require_relative 'parser'

module JsonProjection
  class Projector

    # Initialize a new projector with a stream. The stream is consumed until the
    # JSON structure it contains is finished.
    #
    # stream :: IO
    #           IO stream to read data from.
    #
    # Returns nothing.
    def initialize(stream)
      @parser = Parser.new(stream)
    end

    # Given a JSON schema of properties we are interested in, filter the input
    # stream to just these properties.
    #
    # Note this is not a schema validator, the schema is _navigated_ to
    # determine interesting-ness but if you specify a schema for a key that
    # turns out to be a number it _will be included_. The projection only cares
    # about whether things are interesting while advancing through the stream.
    # To validate the schema, use another class on the resulting projection.
    #
    # schema :: nil | Hash<String, schema>
    #           Map of the keys we are interested in, recurses.
    #
    # Returns a Hash<String, Any> instance or raises a parser error.
    def project(schema)
      event = @parser.next_event
      unless event.is_a?(StartDocument)
        raise StandardError, "expected document start"
      end

      value = filter_subtree(schema, next_event)

      event = @parser.next_event
      unless event.is_a?(EndDocument)
        raise StandardError, "expected document end"
      end

      value
    end

    private

    def next_event
      @parser.next_event
    end

    def filter_subtree(schema, event)
      if event.is_a?(StartArray)
        return filter_array_subtree(schema, event)
      end

      if event.is_a?(StartObject)
        return filter_object_subtree(schema, event)
      end

      raise StandardError, "cannot filter #{event.class} subtree"
    end

    def filter_array_subtree(schema, event)
      unless event.is_a?(StartArray)
        raise StandardError, "expected start array"
      end

      result = []

      while (value_event = next_event) != EndArray.new
        value = if value_event.is_a?(StartObject) || value_event.is_a?(StartArray)
          filter_subtree(schema, value_event)
        else
          build_subtree(value_event)
        end

        result << value
      end

      result
    end

    def filter_object_subtree(schema, event)
      unless event.is_a?(StartObject)
        raise StandardError, "expected start object"
      end

      result = {}

      while (event = next_event) != EndObject.new
        key = event
        unless key.is_a?(Key)
          raise StandardError, "expected a key event"
        end

        # nil schema means reify the subtree from here on
        # otherwise if the schema has a key for this we want it
        is_interesting = schema.nil? || schema.key?(key.key)

        if !is_interesting
          ignore_value
          next
        end

        value_event = next_event

        value = if value_event.is_a?(StartObject) || value_event.is_a?(StartArray)
          # objects can have subschemas, look it up then build the value using
          # filter
          key_schema = if schema.nil?
            nil
          else
            schema[key.key]
          end

          filter_subtree(key_schema, value_event)
        else
          build_subtree(value_event)
        end

        result[key.key] = value
      end

      result
    end

    def build_subtree(event)
      case event

      when Null, Boolean, Number, String
        event.value

      when StartArray
        result = []

        while (event = next_event) != EndArray.new
          result << build_subtree(event)
        end

        result

      when StartObject
        result = {}

        while (event = next_event) != EndObject.new
          key = event
          unless key.is_a?(Key)
            raise StandardError, "expected a key event"
          end

          result[key.key] = build_subtree(next_event)
        end

        result

      else
        raise StandardError, "cannot build subtree for #{event.class}"

      end
    end

    # After reading a key if we know we are not interested in the next value,
    # read and discard all its stream events.
    #
    # Values can be simple (string, numeric, boolean, null) or compound (object
    # or array).
    #
    # Returns nothing.
    def ignore_value
      value_event = next_event

      if value_event.is_a?(Value)
        return
      end

      if value_event.is_a?(StartObject) || value_event.is_a?(StartArray)
        ignore_container
        return
      end

      raise StandardError, "unknown value type to ignore #{value_event.class}"
    end

    # Given the start of an array or object, read until the closing event.
    # Object structures can nest and this is considered.
    #
    # Returns nothing.
    def ignore_container
      depth = 1

      increase_depth_on = [ StartObject.empty, StartArray.empty ]
      decrease_depth_on = [ EndObject.empty, EndArray.empty ]

      while depth > 0
        event = next_event

        if increase_depth_on.include?(event)
          depth += 1
        elsif decrease_depth_on.include?(event)
          depth -= 1
        end
      end
    end

  end
end
