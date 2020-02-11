require 'gammo/tokenizer/debug'

module Gammo
  class Tokenizer
    class ScriptScanner
      include Debug

      attr_reader :scanner, :buffer, :raw_tag

      alias_method :debug?, :debug

      def initialize(scanner, raw_tag:, debug: false)
        @scanner = scanner
        @buffer  = ''
        @raw_tag = raw_tag
        @debug   = debug
      end

      def scan
        scan_script_data
        buffer
      end

      private

      def with_extendable_stack
        begin
          yield
        rescue SystemStackError
          Fiber.new { yield }.resume
        end
      end

      def scan_script_data
       with_extendable_stack do
          consume do |byte|
            byte == ?< ? scan_script_data_less_than_sign : scan_script_data
          end
       end
      end

      def scan_script_data_less_than_sign
        consume do |byte|
          case byte
          when ?/ then return scan_script_data_end_tag_open
          when ?! then return scan_script_data_escape_start
          end
          revert_byte
          scan_script_data
        end
      end

      def scan_script_data_end_tag_open
        return if scan_raw_end_tag? || scanner.eos?
        scan_script_data
      end

      def scan_script_data_escape_start
        consume do |byte|
          return scan_script_data_escape_start_dash if byte == ?-
          revert_byte
          scan_script_data
        end
      end

      def scan_script_data_escape_start_dash
        consume do |byte|
          return scan_script_data_escaped_dash_dash if byte == ?-
          revert_byte
          scan_script_data
        end
      end

      def scan_script_data_escaped
        consume do |byte|
          case byte
          when ?- then return scan_script_data_escaped_dash
          when ?< then return scan_script_data_escaped_less_than_sign
          else return scan_script_data_escaped
          end
        end
      end

      def scan_script_data_escaped_dash
        consume do |byte|
          case byte
          when ?- then return scan_script_data_escaped_dash_dash
          when ?< then return scan_script_data_escaped_less_than_sign
          else return scan_script_data_escaped
          end
        end
      end

      def scan_script_data_escaped_dash_dash
        consume do |byte|
          case byte
          when ?- then return scan_script_data_escaped_dash_dash
          when ?< then return scan_script_data_escaped_less_than_sign
          when ?> then return scan_script_data
          else return scan_script_data_escaped
          end
        end
      end

      def scan_script_data_escaped_less_than_sign
        consume do |byte|
          return scan_script_data_escaped_end_tag_open if byte == ?/
          return scan_script_data_double_escape_start if byte =~ /[a-zA-Z]/
          revert_byte
          scan_script_data
        end
      end

      def scan_script_data_escaped_end_tag_open
        return if scan_raw_end_tag? || scanner.eos?
        scan_script_data_escaped
      end

      def scan_script_data_double_escape_start
        revert_byte
        'script'.each_char.with_index do |ch, index|
          ch = scanner.get_byte
          buffer << ch
          return if scanner.eos?
          unless ch.downcase == 'script'[index]
            revert_byte
            return scan_script_data_escaped
          end
        end
        byte = scanner.get_byte
        buffer << byte
        return if scanner.eos?
        case byte
        when ?\s, ?/, ?> then return scan_script_data_double_escaped
        else
          revert_byte
          scan_script_data_escaped
        end
      end

      def scan_script_data_double_escaped
        consume do |byte|
          case byte
          when ?- then return scan_script_data_double_escaped_dash
          when ?< then return scan_script_data_double_escaped_less_than_sign
          else return scan_script_data_double_escaped
          end
        end
      end

      def scan_script_data_double_escaped_dash
        consume do |byte|
          case byte
          when ?- then return scan_script_data_double_escaped_dash_dash
          when ?< then return scan_script_data_double_escaped_less_than_sign
          else return scan_script_data_double_escaped
          end
        end
      end

      def scan_script_data_double_escaped_dash_dash
        consume do |byte|
          case byte
          when ?- then return scan_script_data_double_escaped_dash_dash
          when ?< then return scan_script_data_double_escaped_less_than_sign
          when ?> then return scan_script_data
          else return scan_script_data_double_escaped
          end
        end
      end

      def scan_script_data_double_escaped_less_than_sign
        consume do |byte|
          return scan_script_data_double_escape_end if byte == ?/
          revert_byte
          scan_script_data_double_escaped
        end
      end

      def scan_script_data_double_escape_end
        if scan_raw_end_tag?
          end_tag = "</#{raw_tag}>"
          # Last matched char needs to be concatenated.
          buffer << scanner.string.slice(scanner.pos, end_tag.length)
          scanner.pos += end_tag.length
          return scan_script_data_escaped
        end
        return if scanner.eos?
        scan_script_data_double_escaped
      end

      def consume
        return unless byte = scanner.get_byte
        buffer << byte
        yield byte
      end

      def revert_byte
        @buffer = buffer.slice(0, buffer.length - 1)
        scanner.unscan
      end

      def scan_raw_end_tag?
        raw_tag.each_char do |ch|
          return false unless byte = scanner.get_byte
          if byte.downcase != ch
            scanner.unscan
            return false
          end
          buffer << byte
        end
        case byte = scanner.get_byte
        when ?>, ?\s, ?/
          desired = 3 + raw_tag.length
          scanner.pos -= desired
          @buffer = buffer.slice(0, buffer.length - desired + 1)
          return true
        when nil
          return false
        else
          buffer << byte
        end
        scanner.unscan
        @buffer = buffer.slice(0, buffer.length - 1)
        false
      end
    end
  end
end
