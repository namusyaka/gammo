module Gammo
  class Parser
    # Section 12.2.6.4.5.
    class AfterHead < InsertionMode
      def text_token(token)
        s = token.data.lstrip
        if s.length < token.data.length
          # add the initial whitespace to the current node.
          parser.add_text token.data.slice(0, token.data.length - s.length)
          halt true if s == ''
          token.data = s
        end
      end

      def start_tag_token(token)
        case token.tag
        when Tags::Html then halt InBody.new(parser).process
        when Tags::Body
          parser.add_element
          parser.frameset_ok = false
          parser.insertion_mode = InBody
          halt true
        when Tags::Frameset
          parser.add_element
          parser.insertion_mode = InFrameset
          halt true
        when Tags::Base, Tags::Basefont, Tags::Bgsound, Tags::Link, Tags::Meta,
          Tags::Noframes, Tags::Script, Tags::Style, Tags::Template, Tags::Title
          parser.open_elements << parser.head
          begin
            halt InHead.new(parser).process
          ensure
            parser.open_elements.delete(parser.head)
          end
        when Tags::Head
          # ignore the token
          halt true
        end
      end

      def end_tag_token(token)
        case token.tag
        when Tags::Body, Tags::Html, Tags::Br
          # drop down to creating an implied <body> tag.
        when Tags::Template
          halt InHead.new(parser).process
        else
          # ignore the token.
          halt true
        end
      end

      def comment_token(token)
        parser.add_child Node::Comment.new(data: token.data)
        halt true
      end

      def doctype_token(token)
        # ignore the token.
        halt true
      end

      def default(_)
        parser.parse_implied_token(Tokenizer::StartTagToken, Tags::Body, Tags::Body.to_s)
        parser.frameset_ok = true
        halt false
      end
    end
  end
end
