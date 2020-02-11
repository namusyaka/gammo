require 'gammo/tokenizer/entity'

module Gammo
  class Tokenizer
    module Escape
      LONGEST_ENTITY_WITHOUT_SEMICOLON = 6
      ESCAPE_REPLACEMENT_TABLE = {
        ?&  => '&amp;',
        ?'  => '&#39;',
        ?<  => '&lt;',
        ?>  => '&gt;',
        ?"  => '&#34;',
        ?\r => '&#13;',
      }.freeze

      REPLACEMENT_TABLE = [
        "\u{20AC}",
        "\u{0081}",
        "\u{201A}",
        "\u{0192}",
        "\u{201E}",
        "\u{2026}",
        "\u{2020}",
        "\u{2021}",
        "\u{02C6}",
        "\u{2030}",
        "\u{0160}",
        "\u{2039}",
        "\u{0152}",
        "\u{008D}",
        "\u{017D}",
        "\u{008F}",
        "\u{0090}",
        "\u{2018}",
        "\u{2019}",
        "\u{201C}",
        "\u{201D}",
        "\u{2022}",
        "\u{2013}",
        "\u{2014}",
        "\u{02DC}",
        "\u{2122}",
        "\u{0161}",
        "\u{203A}",
        "\u{0153}",
        "\u{009D}",
        "\u{017E}",
        "\u{0178}",
      ].freeze

      # Escapes given string according to {ESCAPE_REPLACEMENT_TABLE}.
      def escape(s)
        s.gsub!(/[&'<>"\r]/) { |ch| ESCAPE_REPLACEMENT_TABLE[ch] }
      end

      # Unescapes given data.
      # @param [String] data
      # @return [String, nil]
      def unescape(data, **options)
        return unless data
        data.each_byte.with_index do |byte, i|
          next unless byte.chr == ?&
          dst, src = unescape_entity(data, i, i, **options)
          while src < data.bytes.length
            byte = data.getbyte(src)
            if byte.chr == ?&
              dst, src = unescape_entity(data, dst, src, **options)
            else
              data.setbyte(dst, byte)
              dst, src = dst + 1, src + 1
            end
          end
          return data.byteslice(0, dst)
        end
      end

      private

      def unescape_entity(data, dst, src, in_attribute: false)
        # No need to count "&".
        i, s = 1, data.byteslice(src..-1)
        swap(data, dst, src) if s.length <= 1
        return unescape_sharp_entity(data, s, dst, src, i) if s[i] == ?#
        i = consume_entity_chars(s, i)
        name = s.byteslice(1, i - 1)
        unless name == '' || (in_attribute && like_query_params?(name, s, i))
          entities = Entity::CODEPOINT[name.to_sym]
          entities = entities ? [entities] : Entity::TWO_CODEPOINTS[name.to_sym]
          return replace_entity(entities, data, dst, src, i) if entities
          unless in_attribute
            max = name.length - 1
            max = LONGEST_ENTITY_WITHOUT_SEMICOLON if max > LONGEST_ENTITY_WITHOUT_SEMICOLON
            max.downto(1) do |n|
              if entities = Entity::CODEPOINT[name.byteslice(0, n).to_sym]
                return replace_entity([entities], data, dst, src, n + 1)
              end
            end
          end
        end
        dst1, src1 = dst + i, src + i
        data[dst, dst1] = data[src, src1]
        [dst1, src1]
      end

      def unescape_sharp_entity(data, s, dst, src, i)
        return swap(data, dst, src) if s.length <= 3
        i += 1
        ch = s[i]
        hex = false
        if ch == ?x || ch == ?X
          hex = true
          i += 1
        end
        x = ?\x0
        while i < s.length
          ch = s[i]
          i += 1
          if hex
            if ?0 <= ch && ch <= ?9
              x = 16 * x.ord + ch.ord - ?0.ord
              next
            elsif ?a <= ch && ch <= ?f
              x = 16 * x.ord + ch.ord - ?a.ord + 10
              next
            elsif ?A <= ch && ch <= ?F
              x = 16 * x.ord + ch.ord - ?A.ord + 10
              next
            end
          elsif (?0 <= ch && ch <= ?9)
            x = 10 * x.ord + ch.ord - ?0.ord
            next
          end
          i -= 1 if ch != ?;
          break
        end
        return swap(data, dst, src) if i <= 3
        if 0x80 <= x && x <= 0x9F
          x = REPLACEMENT_TABLE[x - 0x80].ord
        elsif x == 0 || (0xD800 <= x && x <= 0xDFFF) || x > 0x10FFFF
          x = "\u{FFFD}".ord
        end
        x.chr(Encoding::UTF_8).each_byte.with_index { |byte, j| data.setbyte(dst + j, byte) }
        [dst + x.chr(Encoding::UTF_8).bytes.length, src + i]
      end

      def swap(data, dst, src)
        data[dst] = data[src]
        [dst + 1, src + 1]
      end

      def consume_entity_chars(s, i)
        while i < s.length
          ch = s[i]
          i += 1
          next if ?a <= ch && ch <= ?z || ?A <= ch && ch <= ?Z || ?0 <= ch && ch <= ?9
          i -= 1 if ch != ?;
          break
        end
        i
      end

      def like_query_params?(name, s, i)
        name[name.length - 1] != ?; && s.length > i && s[i] == ?=
      end

      def replace_entity(entities, t, dst, src, i)
        [entities.inject(dst) { |sum, ch|
          ch.each_byte.with_index { |byte, j| t.setbyte(sum + j, byte) }
         sum + ch.bytes.length
        }, src + i]
      end
    end
  end
end
