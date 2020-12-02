module Gammo
  class Parser
    # Section 12.2.6.4.22.
    class AfterAfterBody < InsertionMode
      def error_token(_)
        # ignore the token
        halt true
      end

      def character_token(token)
        halt InBody.new(parser).process if token.data.lstrip.length.zero?
      end

      def start_tag_token(token)
        case token.tag
        when Tags::Html
          halt InBody.new(parser).process
        end
      end

      def comment_token(token)
        parser.document.append_child Node::Comment.new(data: token.data)
        halt true
      end

      def doctype_token(token)
        halt InBody.new(parser).process
      end

      def default(_)
        parser.insertion_mode = InBody
        halt false
      end
    end
  end
end
