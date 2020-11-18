module Gammo
  class Parser
    # Section 12.2.6.4.4.
    class InHead < InsertionMode
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
        when Tags::Html
          halt InBody.new(parser).process
        when Tags::Base, Tags::Basefont, Tags::Bgsound, Tags::Link, Tags::Meta
          parser.add_element
          parser.open_elements.pop
          parser.acknowledge_self_closing_tag
          halt true
        when Tags::Noscript
          if parser.scripting?
            parser.parse_generic_raw_text_element
            halt true
          end
          parser.add_element
          parser.insertion_mode = InHeadNoscript
          parser.tokenizer.next_is_not_raw_text!
          halt true
        when Tags::Script, Tags::Title
          parser.add_element
          parser.set_original_insertion_mode
          parser.insertion_mode = Text
          halt true
        when Tags::Noframes, Tags::Style
          parser.parse_generic_raw_text_element
          halt true
        when Tags::Head
          # ignore the token
          halt true
        when Tags::Template
          parser.add_element
          parser.active_formatting_elements << Node::DEFAULT_SCOPE_MARKER
          parser.frameset_ok = false
          parser.insertion_mode = InTemplate
          parser.template_stack << InTemplate
          halt true
        end
      end

      def end_tag_token(token)
        case token.tag
        when Tags::Head
          parser.open_elements.pop
          parser.insertion_mode = AfterHead
          halt true
        when Tags::Body, Tags::Html, Tags::Br
          parser.parse_implied_token(Tokenizer::EndTagToken, Tags::Head, Tags::Head.to_s)
          halt false
        when Tags::Template
          halt true if !parser.open_elements.any? { |oe| oe.tag == Tags::Template }
          # remove this divergence from the HTML5 spec.
          parser.generate_implied_end_tags
          parser.open_elements.reverse_each_with_index do |open_element, index|
            if !open_element.namespace && open_element.tag == Tags::Template
              parser.open_elements = parser.open_elements.slice(0, index)
              break
            end
          end
          parser.clear_active_formatting_elements
          parser.template_stack.pop
          parser.reset_insertion_mode
          halt true
        else
          # ignore the token
          halt true
        end
      end

      def comment_token(token)
        parser.add_child Node::Comment.new(data: token.data)
        halt true
      end

      def doctype_token(token)
        halt true
      end

      def default(_)
        parser.open_elements.pop
        parser.insertion_mode = AfterHead
        halt false
      end
    end
  end
end
