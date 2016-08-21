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

require_relative 'parser/buffer'
require_relative 'parser/events'
require_relative 'parser/errors'
require_relative 'parser/fifo'

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

    # Initialize a new parser with a stream. The stream cursor is advanced as
    # events are drawn from the parser. The parser maintains a small data cache
    # of bytes read from the stream.
    #
    # stream :: IO
    #           IO stream to read data from.
    #
    # Returns nothing.
    def initialize(stream)
      @stream = stream

      @event_buffer = Fifo.new

      @bytes_buffer = Buffer.new
      @bytes = nil

      @pos = -1
      @state = :start_document
      @stack = []

      @value_buffer = ""
      @unicode = ""
    end

    # Draw bytes from the stream until an event can be constructed. May raise
    # IO errors.
    #
    # Returns a JsonProject::StreamEvent subclass or raises StandardError.
    def next_event()
      # Are there any already read events, return the oldest
      @event_buffer, event = @event_buffer.pop
      return event unless event.nil?

      if @state == :end_document
        error("already EOF, no more events")
      end

      while true do
        if @bytes.nil? || @bytes.empty?
          data = stream.read(BUF_SIZE)
          if data == nil # hit EOF
            error("unexpected EOF")
          end

          @bytes = @bytes_buffer.<<(data).each_char.to_a
        end

        head = @bytes.first
        tail = @bytes.slice!(1, @bytes.size - 1)

        @bytes = tail
        @pos += 1

        new_state, events = handle_character(@state, head)

        @state = new_state
        @event_buffer = events.append(@event_buffer)

        unless @event_buffer.empty?
          @event_buffer, event = @event_buffer.pop
          return event
        end
      end
    end

    private

    attr_reader :stream

    # Given a state and new character, return a new state and fifo of events to
    # yield to pull callers.
    #
    # state :: Symbol
    #
    # ch    :: String
    #
    # Returns a tuple of (Symbol, Fifo<Event>) or raises StandardError.
    def handle_character(state, ch)
      case state
      when :start_document
        case ch
        when WS
          return :start_document, Fifo.empty
        when LEFT_BRACE
          @stack.push(:object)

          events = Fifo.pure(StartDocument.empty).push(StartObject.empty)

          return :start_object, events
        when LEFT_BRACKET
          @stack.push(:array)

          events = Fifo.pure(StartDocument.empty).push(StartArray.empty)

          return :start_array, events
        end

        error('Expected whitespace, object `{` or array `[` start token')

      when :start_object
        case ch
        when WS
          return :start_object, Fifo.empty
        when QUOTE
          @stack.push(:key)
          return :start_string, Fifo.empty
        when RIGHT_BRACE
          return end_container(:object)
        end

        error('Expected object key `"` start')

      when :start_string
        case ch
        when QUOTE
          if @stack.pop == :string
            events = Fifo.pure(end_value(@value_buffer.dup))
            @value_buffer.clear

            return :end_value, events
          else # :key
            events = Fifo.pure(Key.new(@value_buffer.dup))
            @value_buffer.clear

            return :end_key, events
          end
        when BACKSLASH
          return :start_escape, Fifo.empty
        when CONTROL
          error('Control characters must be escaped')
        else
          @value_buffer << ch
          return :start_string, Fifo.empty
        end

      when :start_escape
        case ch
        when QUOTE, BACKSLASH, SLASH
          @value_buffer << ch
          return :start_string, Fifo.empty
        when B
          @value_buffer << "\b"
          return :start_string, Fifo.empty
        when F
          @value_buffer << "\f"
          return :start_string, Fifo.empty
        when N
          @value_buffer << "\n"
          return :start_string, Fifo.empty
        when R
          @value_buffer << "\r"
          return :start_string, Fifo.empty
        when T
          @value_buffer << "\t"
          return :start_string, Fifo.empty
        when U
          return :unicode_escape, Fifo.empty
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
              @stack.push(codepoint)
              return :start_surrogate_pair, Fifo.empty
            elsif codepoint >= 0xDC00 && codepoint <= 0xDFFF
              high = @stack.pop
              error('Expected high surrogate pair half') unless high.is_a?(Fixnum)
              pair = ((high - 0xD800) * 0x400) + (codepoint - 0xDC00) + 0x10000
              @value_buffer << pair
              return :start_string, Fifo.empty
            else
              @value_buffer << codepoint
              return :start_string, Fifo.empty
            end
          end

          return :unicode_escape, Fifo.empty
        else
          error('Expected unicode escape hex digit')
        end

      when :start_surrogate_pair
        case ch
        when BACKSLASH
          return :start_surrogate_pair_u, Fifo.empty
        else
          error('Expected low surrogate pair half')
        end

      when :start_surrogate_pair_u
        case ch
        when U
          return :unicode_escape, Fifo.empty
        else
          error('Expected low surrogate pair half')
        end

      when :start_negative_number
        case ch
        when ZERO
          @value_buffer << ch
          return :start_zero, Fifo.empty
        when DIGIT_1_9
          @value_buffer << ch
          return :start_int, Fifo.empty
        else
          error('Expected 0-9 digit')
        end

      when :start_zero
        case ch
        when POINT
          @value_buffer << ch
          return :start_float, Fifo.empty
        when EXPONENT
          @value_buffer << ch
          return :start_exponent, Fifo.empty
        else
          events = Fifo.pure(end_value(@value_buffer.to_i))
          @value_buffer.clear

          state = :end_value

          state, new_events = handle_character(state, ch)

          return state, new_events.append(events)
        end

      when :start_float
        case ch
        when DIGIT
          @value_buffer << ch
          return :in_float, Fifo.empty
        end

        error('Expected 0-9 digit')

      when :in_float
        case ch
        when DIGIT
          @value_buffer << ch
          return :in_float, Fifo.empty
        when EXPONENT
          @value_buffer << ch
          return :start_exponent, Fifo.empty
        else
          events = Fifo.pure(end_value(@value_buffer.to_f))
          @value_buffer.clear

          state = :end_value

          state, new_events = handle_character(state, ch)

          return state, new_events.append(events)
        end

      when :start_exponent
        case ch
        when MINUS, PLUS, DIGIT
          @value_buffer << ch
          return :in_exponent, Fifo.empty
        end

        error('Expected +, -, or 0-9 digit')

      when :in_exponent
        case ch
        when DIGIT
          @value_buffer << ch
          return :in_exponent, Fifo.empty
        else
          error('Expected 0-9 digit') unless @value_buffer =~ DIGIT_END

          events = Fifo.pure(end_value(@value_buffer.to_f))
          @value_buffer.clear

          state = :end_value

          state, new_events = handle_character(state, ch)

          return state, new_events.append(events)
        end

      when :start_int
        case ch
        when DIGIT
          @value_buffer << ch
          return :start_int, Fifo.empty
        when POINT
          @value_buffer << ch
          return :start_float, Fifo.empty
        when EXPONENT
          @value_buffer << ch
          return :start_exponent, Fifo.empty
        else
          events = Fifo.pure(end_value(@value_buffer.to_i))
          @value_buffer.clear

          state = :end_value

          state, new_events = handle_character(state, ch)

          return state, new_events.append(events)
        end

      when :start_true
        state, event = keyword(TRUE_KEYWORD, true, TRUE_RE, ch)
        if state.nil?
          return :start_true, Fifo.empty
        end

        return state, Fifo.pure(event)
      when :start_false
        state, event = keyword(FALSE_KEYWORD, false, FALSE_RE, ch)
        if state.nil?
          return :start_false, Fifo.empty
        end

        return state, Fifo.pure(event)
      when :start_null
        state, event = keyword(NULL_KEYWORD, nil, NULL_RE, ch)
        if state.nil?
          return :start_null, Fifo.empty
        end

        return state, Fifo.pure(event)

      when :end_key
        case ch
        when WS
          return :end_key, Fifo.empty
        when COLON
          return :key_sep, Fifo.empty
        end

        error('Expected colon key separator')

      when :key_sep
        case ch
        when WS
          return :key_sep, Fifo.empty
        else
          return start_value(ch)
        end

      when :start_array
        case ch
        when WS
          return :start_array, Fifo.empty
        when RIGHT_BRACKET
          return end_container(:array)
        else
          return start_value(ch)
        end

      when :end_value
        case ch
        when WS
          return :end_value, Fifo.empty
        when COMMA
          return :value_sep, Fifo.empty
        when RIGHT_BRACE
          return end_container(:object)
        when RIGHT_BRACKET
          return end_container(:array)
        end

        error('Expected comma `,` object `}` or array `]` close')

      when :value_sep
        if @stack[-1] == :object
          case ch
          when WS
            return :value_sep, Fifo.empty
          when QUOTE
            @stack.push(:key)
            return :start_string, Fifo.empty
          end

          error('Expected whitespace or object key start `"`')
        end

        case ch
        when WS
          return :value_sep, Fifo.empty
        else
          return start_value(ch)
        end

      when :end_document
        error('Unexpected data') unless ch =~ WS
      end
    end

    # Complete an object or array container value type.
    #
    # type - The Symbol, :object or :array, of the expected type.
    #
    # Raises a JSON::Stream::ParserError if the expected container type
    #   was not completed.
    #
    # Returns a tuple of (Symbol, Fifo<Event>) instance or raises a
    # JsonProjection::ParseError if the character does not signal the start of
    # a value.
    def end_container(type)
      state = :end_value
      events = Fifo.empty

      if @stack.pop == type
        case type
        when :object then
          events = events.push(EndObject.empty)
        when :array  then
          events = events.push(EndArray.empty)
        end
      else
        error("Expected end of #{type}")
      end

      if @stack.empty?
        state = :end_document
        events = events.push(EndDocument.empty)
      end

      return state, events
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
      elsif @value_buffer == word
        event = end_value(value)
        @value_buffer.clear

        return :end_value, event
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
      when LEFT_BRACE
        @stack.push(:object)
        return :start_object, Fifo.pure(StartObject.empty)
      when LEFT_BRACKET
        @stack.push(:array)
        return :start_array, Fifo.pure(StartArray.empty)
      when QUOTE
        @stack.push(:string)
        return :start_string, Fifo.empty
      when T
        @value_buffer << ch
        return :start_true, Fifo.empty
      when F
        @value_buffer << ch
        return :start_false, Fifo.empty
      when N
        @value_buffer << ch
        return :start_null, Fifo.empty
      when MINUS
        @value_buffer << ch
        return :start_negative_number, Fifo.empty
      when ZERO
        @value_buffer << ch
        return :start_zero, Fifo.empty
      when DIGIT_1_9
        @value_buffer << ch
        return :start_int, Fifo.empty
      end

      error('Expected value')
    end

    # Advance the state machine and construct the event for the value just read.
    #
    # Returns a JsonProjection::StreamEvent subclass.
    def end_value(value)
      case value
      when TrueClass, FalseClass
        Boolean.new(value)
      when Numeric
        Number.new(value)
      when ::String
        JsonProjection::String.new(value)
      when NilClass
        Null.new(nil)
      end
    end

    def error(message)
      raise ParseError, "#{message}: char #{@pos}"
    end
  end

end
