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
    # schema :: nil | Hash<String, schema>
    #           Map of the keys we are interested in, recurses.
    #
    # Returns a Hash<String, Any> instance or raises a parser error.
    def project(schema)
      event = @parser.next_event
      unless event.is_a?(StartDocument)
        raise StandardError, "expected document start"
      end

      value = build_value(schema)

      event = @parser.next_event
      unless event.is_a?(EndDocument)
        raise StandardError, "expected document end"
      end

      return value
    end

    private

    def build_value(schema)
      case schema
      when NilClass
        # Once nil is hit in the schema the subtree is built fully
        build_subtree
      when Hash
        # If the schema is a hash only build subtrees for the interesting key
        filter_subtree(schema)
      end
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
          key = next_event
          unless key.is_a?(Key)
            raise StandardError, "expected a key event"
          end

          result[key.key] = build_subtree(next_event)
        end

      else
        raise StandardError, "cannot build subtree for #{event.class}"

      end
    end

    def filter_subtree(schema)

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

      simple_types = [
        String,
        Number,
        Boolean,
        Null,
      ]

      # Basic case, one value to read
      if simple_types.include?(value_event.class)
        return
      end

      if value_event.is_a?(StartObject)
        ignore_container
        return
      end

      if value_event.is_a?(StartArray)
        ignore_container
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
