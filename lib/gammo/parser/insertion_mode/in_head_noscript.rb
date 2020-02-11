module Gammo
  class Parser
    # 12.2.6.4.5.
    class InHeadNoscript < InsertionMode
      def doctype_token(_)
        # ignore the token.
        halt true
      end

      def comment_token(_)
        halt InHead.new(parser).process
      end

      def start_tag_token(token)
        case token.tag
        when Tags::Html then halt InBody.new(parser).process
        when Tags::Basefont, Tags::Bgsound, Tags::Link, Tags::Meta, Tags::Noframes, Tags::Style
          halt InHead.new(parser).process
        when Tags::Head, Tags::Noscript
          # ignore the token.
          halt true
        end
      end

      def end_tag_token(token)
        case token.tag
        when Tags::Noscript
          parser.open_elements.pop
          parser.insertion_mode = InHead
          halt true
        when Tags::Br
          # no-op
        else
          # ignore the token.
          halt true
        end
      end

      def text_token(token)
        halt InHead.new(parser).process if token.data.lstrip == ''
      end

      def default(token)
        parser.open_elements.pop
        raise ParseError, 'the new current node will be a head element.'\
          if parser.top.tag != Tags::Head
        parser.insertion_mode = InHead
        halt false
      end
    end
  end
end
