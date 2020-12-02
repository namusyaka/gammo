require 'gammo/parser/insertion_mode/after_after_frameset'

module Gammo
  class Parser
    # Section 12.2.6.4.21.
    class AfterFrameset < InsertionMode
      def comment_token(token)
        parser.add_child Node::Comment.new(data: token.data)
      end

      def character_token(token)
        s = token.data.gsub(/[^\s]/, '')
        parser.add_text(s) unless s.empty?
      end

      def start_tag_token(token)
        case token.tag
        when Tags::Html
          halt InBody.new(parser).process
        when Tags::Noframes
          halt InHead.new(parser).process
        end
      end

      def end_tag_token(token)
        case token.tag
        when Tags::Html
          parser.insertion_mode = AfterAfterFrameset
          halt true
        end
      end

      def default(_)
        # ignore the token
        halt true
      end
    end
  end
end
