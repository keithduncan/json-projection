# encoding: UTF-8

# Based on JSON::Stream::Buffer from https://github.com/dgraham/json-stream
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

module JsonProjection

  # A character buffer that expects a UTF-8 encoded stream of bytes.
  # This handles truncated multi-byte characters properly so we can just
  # feed it binary data and receive a properly formatted UTF-8 String as
  # output.
  #
  # More UTF-8 parsing details are available at:
  #
  #   http://en.wikipedia.org/wiki/UTF-8
  #   http://tools.ietf.org/html/rfc3629#section-3
  class Buffer
    def initialize
      @state = :start
      @buffer = []
      @need = 0
    end

    # Fill the buffer with a String of binary UTF-8 encoded bytes. Returns
    # as much of the data in a UTF-8 String as we have. Truncated multi-byte
    # characters are saved in the buffer until the next call to this method
    # where we expect to receive the rest of the multi-byte character.
    #
    # data - The partial binary encoded String data.
    #
    # Raises JSON::Stream::ParserError if the UTF-8 byte sequence is malformed.
    #
    # Returns a UTF-8 encoded String.
    def <<(data)
      # Avoid state machine for complete UTF-8.
      if @buffer.empty?
        data.force_encoding(Encoding::UTF_8)
        return data if data.valid_encoding?
      end

      bytes = []
      data.each_byte do |byte|
        case @state
        when :start
          if byte < 128
            bytes << byte
          elsif byte >= 192
            @state = :multi_byte
            @buffer << byte
            @need =
              case
              when byte >= 240 then 4
              when byte >= 224 then 3
              when byte >= 192 then 2
              end
          else
            error('Expected start of multi-byte or single byte char')
          end
        when :multi_byte
          if byte > 127 && byte < 192
            @buffer << byte
            if @buffer.size == @need
              bytes += @buffer.slice!(0, @buffer.size)
              @state = :start
            end
          else
            error('Expected continuation byte')
          end
        end
      end

      # Build UTF-8 encoded string from completed codepoints.
      bytes.pack('C*').force_encoding(Encoding::UTF_8).tap do |text|
        error('Invalid UTF-8 byte sequence') unless text.valid_encoding?
      end
    end

    # Determine if the buffer contains partial UTF-8 continuation bytes that
    # are waiting on subsequent completion bytes before a full codepoint is
    # formed.
    #
    # Examples
    #
    #   bytes = "é".bytes
    #
    #   buffer << bytes[0]
    #   buffer.empty?
    #   # => false
    #
    #   buffer << bytes[1]
    #   buffer.empty?
    #   # => true
    #
    # Returns true if the buffer is empty.
    def empty?
      @buffer.empty?
    end

    private

    def error(message)
      raise ParseError, message
    end
  end

end
