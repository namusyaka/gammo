module Gammo
  class Parser
    # Section 12.2.6.4.2
    class BeforeHTML < InsertionMode
      # Ignores the token.
      def doctype_token(_)
        halt true
      end

      def text_token(token)
        token.data = token.data.lstrip
        # it's all whitespace so ignore it.
        halt true if token.data.length.zero?
      end

      def start_tag_token(token)
        return unless token.tag == Tags::Html
        parser.add_element
        parser.insertion_mode = BeforeHead
        halt true
      end

      def end_tag_token(token)
        case token.tag
        when Tags::Head, Tags::Body, Tags::Html, Tags::Br
          parser.parse_implied_token Tokenizer::StartTagToken, Tags::Html, Tags::Html.to_s
          halt false
        else
          # ignore the token.
          halt true
        end
      end

      def comment_token(token)
        parser.document.append_child Node::Comment.new(data: token.data)
        halt true
      end

      def default(_)
        parser.parse_implied_token Tokenizer::StartTagToken, Tags::Html, Tags::Html.to_s
        halt false
      end
    end
  end
end
