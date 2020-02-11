module Gammo
  class Parser
    # Section 12.2.6.4.23.
    class AfterAfterFrameset < InsertionMode
      def comment_token(token)
        parser.document.append_child Node::Comment.new(data: token.data)
      end

      def text_token(token)
        halt InBody.new(parser).process unless token.data.gsub(/[^\s]/, '').empty?
      end

      def start_tag_token(token)
        case token.tag
        when Tags::Html
          halt InBody.new(parser).process
        when Tags::Noframes
          halt InHead.new(parser).process
        end
      end

      def doctype_token(token)
        halt InBody.new(parser).process
      end

      def default(_)
        # ignore the token
        halt true
      end
    end
  end
end
