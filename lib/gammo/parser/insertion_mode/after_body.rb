require 'gammo/node'
module Gammo
  class Parser
    # Section 12.2.6.4.19.
    class AfterBody < InsertionMode
      def error_token(_)
        # ignore the token
        true
      end

      def character_token(token)
        s = token.data.lstrip
        halt InBody.new(parser).process if s.length.zero?
      end

      def start_tag_token(token)
        case token.tag
        when Tags::Html
          halt InBody.new(parser).process
        end
      end

      def end_tag_token(token)
        case token.tag
        when Tags::Html
          parser.insertion_mode = AfterAfterBody unless parser.fragment?
          halt true
        end
      end

      def comment_token(token)
        open_elements = parser.open_elements
        if open_elements.length < 1 || open_elements.first.tag != Tags::Html
          raise ParseError, 'bad parser state: <html> element not found, in the after-body insertion mode'
        end
        open_elements.first.append_child Node::Comment.new(data: token.data)
        halt true
      end

      def default(_)
        parser.insertion_mode = InBody
        halt false
      end
    end
  end
end
