module Gammo
  class Parser
    # Section 12.2.6.4.20.
    class InFrameset < InsertionMode
      def comment_token(token)
        parser.add_child Node::Comment.new(data: token.data)
      end

      def character_token(token)
        text = token.data.each_char.with_object(String.new) { |c, s| s << c if c == ?\s }
        parser.add_text(text) if text != ''
      end

      def start_tag_token(token)
        case token.tag
        when Tags::Html
          halt InBody.new(parser).process
        when Tags::Frameset
          parser.add_element
        when Tags::Frame
          parser.add_element
          parser.open_elements.pop
          parser.acknowledge_self_closing_tag
        when Tags::Noframes
          halt InHead.new(parser).process
        end
      end

      def end_tag_token(token)
        case token.tag
        when Tags::Frameset
          if parser.open_elements.last.tag != Tags::Html
            parser.open_elements.pop
            if parser.open_elements.last.tag != Tags::Frameset
              parser.insertion_mode = AfterFrameset
              halt true
            end
          end
        end
      end

      def default(_)
        # ignore the token
        halt true
      end
    end
  end
end
