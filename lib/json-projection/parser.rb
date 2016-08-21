# encoding: UTF-8

# Based on JSON::Stream::Parser from https://github.com/dgraham/json-stream
# license preserved below.
#
# Copyright (c) 2010-2014 David Graham
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative 'events'
require_relative 'errors'

module JsonProjection

  # A streaming JSON parser that generates SAX-like events for state changes.
  # Use the json gem for small documents. Use this for huge documents that
  # won't fit in memory.
  class Parser
    BUF_SIZE      = 4096
    CONTROL       = /[\x00-\x1F]/
    WS            = /[ \n\t\r]/
    HEX           = /[0-9a-fA-F]/
    DIGIT         = /[0-9]/
    DIGIT_1_9     = /[1-9]/
    DIGIT_END     = /\d$/
    TRUE_RE       = /[rue]/
    FALSE_RE      = /[alse]/
    NULL_RE       = /[ul]/
    TRUE_KEYWORD  = 'true'
    FALSE_KEYWORD = 'false'
    NULL_KEYWORD  = 'null'
    LEFT_BRACE    = '{'
    RIGHT_BRACE   = '}'
    LEFT_BRACKET  = '['
    RIGHT_BRACKET = ']'
    BACKSLASH     = '\\'
    SLASH         = '/'
    QUOTE         = '"'
    COMMA         = ','
    COLON         = ':'
    ZERO          = '0'
    MINUS         = '-'
    PLUS          = '+'
    POINT         = '.'
    EXPONENT      = /[eE]/
    B,F,N,R,T,U   = %w[b f n r t u]

    # Initialize a new scanner with a stream. The cursor is advanced as events
    # are drawn from the scanner.
    #
    # stream :: IO
    #           IO stream to read data from.
    #
    # Returns nothing.
    def initialize(steam)
      @stream = stream

      @event_buffer = Fifo.new

      @bytes_buffer = Buffer.new

      @pos = -1
      @state = :start_document
      @stack = []

      @value_buffer = nil
    end

    # Draw bytes from the stream until an event can be constructed. May raise
    # IO errors.
    #
    # Returns a JsonProject::StreamEvent subclass or raises StandardError.
    def next_event()
      # Are there any already read events, return the oldest
      event = @event_buffer.pop
      unless event.nil?
        return event
      end

      if @state == :end_document
        error("already EOF, no more events")
      end

      while true do
        if @bytes_buffer.empty?
          data = stream.read(BUF_SIZE)
          if data == nil # hit EOF
            error("unexpected EOF")
          end

          @bytes_buffer << data
        end

        @bytes_buffer.each_char do |ch|
          @pos += 1
          case @state
          when :start_document
            case ch
            when WS
              # nop
            when LEFT_BRACE
              @state = :start_object
              @stack.push(:object)

              @event_buffer.push(StartObject.new)
            when LEFT_BRACKET
              @state = :start_array
              @stack.push(:array)

              @event_buffer.push(StartArray.new)
            else
              error('Expected whitespace, object `{` or array `[` start token')
            end

            return StartDocument.new
          when :start_object
            case ch
            when WS
              # ignore
            when QUOTE
              @state = :start_string
              @stack.push(:key)
            when RIGHT_BRACE
              return prepend_and_pop(end_container(:object))
            else
              error('Expected object key `"` start')
            end
          when :start_string
            case ch
            when QUOTE
              if @stack.pop == :string
                event = end_value(@value_buffer.dup)
                @value_buffer.clear

                return event
              else # :key
                @state = :end_key

                event = Key.new(@value_buffer.dup)
                return event
              end
            when BACKSLASH
              @state = :start_escape
            when CONTROL
              error('Control characters must be escaped')
            else
              @value_buffer << ch
            end
          when :start_escape
            case ch
            when QUOTE, BACKSLASH, SLASH
              @value_buffer << ch
              @state = :start_string
            when B
              @value_buffer << "\b"
              @state = :start_string
            when F
              @value_buffer << "\f"
              @state = :start_string
            when N
              @value_buffer << "\n"
              @state = :start_string
            when R
              @value_buffer << "\r"
              @state = :start_string
            when T
              @value_buffer << "\t"
              @state = :start_string
            when U
              @state = :unicode_escape
            else
              error('Expected escaped character')
            end
          when :unicode_escape
            case ch
            when HEX
              @unicode << ch
              if @unicode.size == 4
                codepoint = @unicode.slice!(0, 4).hex
                if codepoint >= 0xD800 && codepoint <= 0xDBFF
                  error('Expected low surrogate pair half') if @stack[-1].is_a?(Fixnum)
                  @state = :start_surrogate_pair
                  @stack.push(codepoint)
                elsif codepoint >= 0xDC00 && codepoint <= 0xDFFF
                  high = @stack.pop
                  error('Expected high surrogate pair half') unless high.is_a?(Fixnum)
                  pair = ((high - 0xD800) * 0x400) + (codepoint - 0xDC00) + 0x10000
                  @value_buffer << pair
                  @state = :start_string
                else
                  @value_buffer << codepoint
                  @state = :start_string
                end
              end
            else
              error('Expected unicode escape hex digit')
            end
          when :start_surrogate_pair
            case ch
            when BACKSLASH
              @state = :start_surrogate_pair_u
            else
              error('Expected low surrogate pair half')
            end
          when :start_surrogate_pair_u
            case ch
            when U
              @state = :unicode_escape
            else
              error('Expected low surrogate pair half')
            end
          when :start_negative_number
            case ch
            when ZERO
              @state = :start_zero
              @value_buffer << ch
            when DIGIT_1_9
              @state = :start_int
              @value_buffer << ch
            else
              error('Expected 0-9 digit')
            end
          when :start_zero
            case ch
            when POINT
              @state = :start_float
              @value_buffer << ch
            when EXPONENT
              @state = :start_exponent
              @value_buffer << ch
            else
              end_value(@value_buffer.to_i)
              @value_buffer = ""
              @pos -= 1
              redo
            end
          when :start_float
            case ch
            when DIGIT
              @state = :in_float
              @value_buffer << ch
            else
              error('Expected 0-9 digit')
            end
          when :in_float
            case ch
            when DIGIT
              @value_buffer << ch
            when EXPONENT
              @state = :start_exponent
              @value_buffer << ch
            else
              end_value(@value_buffer.to_f)
              @value_buffer = ""
              @pos -= 1
              redo
            end
          when :start_exponent
            case ch
            when MINUS, PLUS, DIGIT
              @state = :in_exponent
              @buf << ch
            else
              error('Expected +, -, or 0-9 digit')
            end
          when :in_exponent
            case ch
            when DIGIT
              @value_buffer << ch
            else
              error('Expected 0-9 digit') unless @value_buffer =~ DIGIT_END
              end_value(@value_buffer.to_f)
              @value_buffe = ""
              @pos -= 1
              redo
            end
          when :start_int
            case ch
            when DIGIT
              @value_buffer << ch
            when POINT
              @state = :start_float
              @value_buffer << ch
            when EXPONENT
              @state = :start_exponent
              @value_buffer << ch
            else
              end_value(@value_buffer.to_i)
              @value_buffer = ""
              @pos -= 1
              redo
            end
          when :start_true
            event = keyword(TRUE_KEYWORD, true, TRUE_RE, ch)
            unless event.nil?
              return event
            end
          when :start_false
            event = keyword(FALSE_KEYWORD, false, FALSE_RE, ch)
            unless event.nil?
              return event
            end
          when :start_null
            event = keyword(NULL_KEYWORD, nil, NULL_RE, ch)
            unless event.nil?
              return event
            end
          when :end_key
            case ch
            when COLON
              @state = :key_sep
            when WS
              # ignore
            else
              error('Expected colon key separator')
            end
          when :key_sep
            start_value(ch)
          when :start_array
            case ch
            when WS
              # ignore
            when RIGHT_BRACKET
              return prepend_and_pop(end_container(:array))
            else
              start_value(ch)
            end
          when :end_value
            case ch
            when WS
              # ignore
            when COMMA
              @state = :value_sep
            when RIGHT_BRACE
              return prepend_and_pop(end_container(:object))
            when RIGHT_BRACKET
              return prepend_and_pop(end_container(:array))
            else
              error('Expected comma `,` object `}` or array `]` close')
            end
          when :value_sep
            if @stack[-1] == :object
              case ch
              when WS
                # ignore
              when QUOTE
                @state = :start_string
                @stack.push(:key)
              else
                error('Expected object key start')
              end
            else
              start_value(ch)
            end
          when :end_document
            error('Unexpected data') unless ch =~ WS
          end
        end
      end
    end

    # Advance the stream cursor until after the given event class. This method
    # considers Object and Array nesting, use it to skip a subset of the input
    # document stream.
    #
    # If the document is malformed and EOF is reached before the terminating
    # event, JsonProject::ParseError is raised.
    #
    # Returns nothing, may raise StandardError.
    def read_until(klass)

    end

    private

    # Complete an object or array container value type.
    #
    # type - The Symbol, :object or :array, of the expected type.
    #
    # Raises a JSON::Stream::ParserError if the expected container type
    #   was not completed.
    #
    # Returns a Fifo<JsonProjection::StreamEvent> instance or raises a
    # JsonProjection::ParseError if the character does not signal the start of
    # a value.
    def end_container(type)
      events = Fifo.new

      @state = :end_value

      if @stack.pop == type
        case type
        when :object then
          events.push(EndObject.new)
        when :array  then
          events.push(EndArray.new)
        end
      else
        error("Expected end of #{type}")
      end

      if @stack.empty?
        @state = :end_document
        events.push(EndDocument.new)
      end

      return events
    end

    # Parse one of the three allowed keywords: true, false, null.
    #
    # word  - The String keyword ('true', 'false', 'null').
    # value - The Ruby value (true, false, nil).
    # re    - The Regexp of allowed keyword characters.
    # ch    - The current String character being parsed.
    #
    # Raises a JSON::Stream::ParserError if the character does not belong
    #   in the expected keyword.
    #
    # Returns a JsonProjection::StreamEvent? instance or raises.
    def keyword(word, value, re, ch)
      if ch =~ re
        @value_buffer << ch
      else
        error("Expected #{word} keyword")
      end

      if @value_buffer.size != word.size
        return nil
      end

      if @value_buffer == word
        @value_buffer = ""
        return end_value(value)
      else
        error("Expected #{word} keyword")
      end
    end

    # Process the first character of one of the seven possible JSON
    # values: object, array, string, true, false, null, number.
    #
    # ch :: String
    #       The current character String.
    #
    # Returns a JsonProjection::StreamEvent? subclass.
    def start_value(ch)
      case ch
      when WS
        return nil
      when LEFT_BRACE
        @state = :start_object
        @stack.push(:object)
        return StartObject.new
      when LEFT_BRACKET
        @state = :start_array
        @stack.push(:array)
        return StartArray.new
      when QUOTE
        @state = :start_string
        @stack.push(:string)
        return nil
      when T
        @state = :start_true
        @value_buffer << ch
        return nil
      when F
        @state = :start_false
        @value_buffer << ch
        return nil
      when N
        @state = :start_null
        @value_buffer << ch
        return nil
      when MINUS
        @state = :start_negative_number
        @value_buffer << ch
        return nil
      when ZERO
        @state = :start_zero
        @value_buffer << ch
        return nil
      when DIGIT_1_9
        @state = :start_int
        @value_buffer << ch
        return nil
      end

      error('Expected value')
    end

    # Advance the state machine and construct the event for the value just read.
    #
    # Returns a JsonProjection::StreamEvent subclass.
    def end_value(value)
      @state = :end_value

      case value
      when TrueClass, FalseClass
        return Boolean.new(value)
      when Numeric
        return Number.new(value)
      when ::String
        return JsonProjection::String.new(value)
      when NilClass
        return Null.new
      end
    end

    def prepend_and_pop(events)
      @event_buffer = events.concat(@event_buffer)
      return @event_buffer.pop
    end

    def error(message)
      raise ParseError, "#{message}: char #{@pos}"
    end
  end

end
