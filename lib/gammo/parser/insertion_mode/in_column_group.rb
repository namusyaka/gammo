module Gammo
  class Parser
    # Section 12.2.6.4.12.
    class InColumnGroup < InsertionMode
      def text_token(token)
        s = token.data.lstrip
        if s.length < token.data.length
          # add the initial whitespace to the current node.
          parser.add_text token.data.slice(0, token.data.length - s.length)
          halt true if s == ''
          token.data = s
        end
      end

      def comment_token(token)
        parser.add_child(Node::Comment.new(data: token.data))
        halt true
      end

      def doctype_token(_)
        halt true
      end

      def start_tag_token(token)
        case token.tag
        when Tags::Html
          halt InBody.new(parser).process
        when Tags::Col
          parser.add_element
          parser.open_elements.pop
          parser.acknowledge_self_closing_tag
          halt true
        when Tags::Template
          halt InHead.new(parser).process
        end
      end

      def end_tag_token(token)
        case token.tag
        when Tags::Colgroup
          if parser.top.tag == Tags::Colgroup
            parser.open_elements.pop
            parser.insertion_mode = InTable
          end
          halt true
        when Tags::Col
          # ignore the token
          halt true
        when Tags::Template
          halt InHead.new(parser).process
        end
      end

      def error_token(_)
        halt InBody.new(parser).process
      end

      def default(_)
        halt true if parser.top.tag != Tags::Colgroup
        parser.open_elements.pop
        parser.insertion_mode = InTable
        halt false
      end
    end
  end
end
