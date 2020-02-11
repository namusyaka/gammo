require 'gammo/attribute'

module Gammo
  class Parser
    # Section 12.2.6.4.1
    class Initial < InsertionMode
      def text_token(token)
        token.data = token.data.lstrip
        # it's all whitespace so ignore it.
        halt true if token.data.length.zero?
      end

      def comment_token(token)
        parser.document.append_child(Node::Comment.new(data: token.data))
        halt true
      end

      def doctype_token(token)
        n, quirks = parse_doctype(token.data)
        parser.document.append_child(n)
        parser.quirks = quirks
        parser.insertion_mode = BeforeHTML
        halt true
      end

      def default(_)
        parser.quirks = true
        parser.insertion_mode = BeforeHTML
        halt false
      end

      QUIRKY_IDS = [
        "+//silmaril//dtd html pro v0r11 19970101//",
        "-//advasoft ltd//dtd html 3.0 aswedit + extensions//",
        "-//as//dtd html 3.0 aswedit + extensions//",
        "-//ietf//dtd html 2.0 level 1//",
        "-//ietf//dtd html 2.0 level 2//",
        "-//ietf//dtd html 2.0 strict level 1//",
        "-//ietf//dtd html 2.0 strict level 2//",
        "-//ietf//dtd html 2.0 strict//",
        "-//ietf//dtd html 2.0//",
        "-//ietf//dtd html 2.1e//",
        "-//ietf//dtd html 3.0//",
        "-//ietf//dtd html 3.2 final//",
        "-//ietf//dtd html 3.2//",
        "-//ietf//dtd html 3//",
        "-//ietf//dtd html level 0//",
        "-//ietf//dtd html level 1//",
        "-//ietf//dtd html level 2//",
        "-//ietf//dtd html level 3//",
        "-//ietf//dtd html strict level 0//",
        "-//ietf//dtd html strict level 1//",
        "-//ietf//dtd html strict level 2//",
        "-//ietf//dtd html strict level 3//",
        "-//ietf//dtd html strict//",
        "-//ietf//dtd html//",
        "-//metrius//dtd metrius presentational//",
        "-//microsoft//dtd internet explorer 2.0 html strict//",
        "-//microsoft//dtd internet explorer 2.0 html//",
        "-//microsoft//dtd internet explorer 2.0 tables//",
        "-//microsoft//dtd internet explorer 3.0 html strict//",
        "-//microsoft//dtd internet explorer 3.0 html//",
        "-//microsoft//dtd internet explorer 3.0 tables//",
        "-//netscape comm. corp.//dtd html//",
        "-//netscape comm. corp.//dtd strict html//",
        "-//o'reilly and associates//dtd html 2.0//",
        "-//o'reilly and associates//dtd html extended 1.0//",
        "-//o'reilly and associates//dtd html extended relaxed 1.0//",
        "-//softquad software//dtd hotmetal pro 6.0::19990601::extensions to html 4.0//",
        "-//softquad//dtd hotmetal pro 4.0::19971010::extensions to html 4.0//",
        "-//spyglass//dtd html 2.0 extended//",
        "-//sq//dtd html 2.0 hotmetal + extensions//",
        "-//sun microsystems corp.//dtd hotjava html//",
        "-//sun microsystems corp.//dtd hotjava strict html//",
        "-//w3c//dtd html 3 1995-03-24//",
        "-//w3c//dtd html 3.2 draft//",
        "-//w3c//dtd html 3.2 final//",
        "-//w3c//dtd html 3.2//",
        "-//w3c//dtd html 3.2s draft//",
        "-//w3c//dtd html 4.0 frameset//",
        "-//w3c//dtd html 4.0 transitional//",
        "-//w3c//dtd html experimental 19960712//",
        "-//w3c//dtd html experimental 970421//",
        "-//w3c//dtd w3 html//",
        "-//w3o//dtd w3 html 3.0//",
        "-//webtechs//dtd mozilla html 2.0//",
        "-//webtechs//dtd mozilla html//"
      ].freeze

      def parse_doctype(s)
        node = Node::Doctype.new
        pos = s.index(?\s)
        pos = s.length unless pos
        node.data = s.slice(0, pos)
        quirks = false
        quirks = true if node.data != 'html'
        node.data = node.data.downcase
        s = s.slice(pos..-1).lstrip
        return [node, quirks || s != ''] if s.length < 6

        key = s.slice(0, 6).downcase
        s = s.slice(6..-1)
        while key == 'public' || key == 'system'
          s = s.lstrip
          break if s.empty?
          quote = s[0]
          break if quote != ?" && quote != ?'
          s = s.slice(1..-1)
          id = ''
          q = s.index(quote)
          if q
            id = s.slice(0, q)
            s = s.slice((q + 1)..-1)
          else
            id = s
            s = ''
          end
          node.attributes << Attribute.new(key: key, value: id)
          key = key == 'public' ? 'system' : ''
          if key != '' || s != ''
            quirks = true
          elsif node.attributes.length > 0
            if node.attributes.first.key == 'public'
              pub = node.attributes.first.value.downcase
              case pub
              when '-//w3o//dtd w3 html strict 3.0//en//', '-/w3d/dtd html 4.0 transitional/en', 'html'
                quirks = true
              else
                QUIRKY_IDS.each do |quirky|
                  if pub.start_with?(quirky)
                    quirks = true
                    break
                  end
                end
              end
              if node.attributes.length == 1 && pub.start_with?('-//w3c//dtd html 4.01 frameset//') || pub.start_with?('-//w3c//dtd html 4.01 transitional//')
                quirks = true
              end
            end
            last = node.attributes.last
            if last.key == 'system' && last.value.downcase == 'http://www.ibm.com/data/dtd/v11/ibmxhtml1-transitional.dtd'
              quirks = true
            end
          end
        end
        [node, quirks]
      end

      private :parse_doctype
    end
  end
end
