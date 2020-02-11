module Gammo
  class Parser
    # Section 12.2.6.4.7.
    class Text < InsertionMode
      def error_token(token)
        parser.open_elements.pop
      end

      def text_token(token)
        d = token.data
        n = parser.open_elements.last
        if n.tag == Tags::Textarea && n.first_child.nil?
          d = d.slice(1..-1) if d != "" && d.start_with?(?\r)
          d = d.slice(1..-1) if d != "" && d.start_with?(?\n)
        end
        halt true if d == ""
        parser.add_text(d)
        halt true
      end

      def end_tag_token(token)
        parser.open_elements.pop
      end

      def default(token)
        parser.insertion_mode = parser.original_insertion_mode
        parser.original_insertion_mode = nil
        halt token.instance_of?(Tokenizer::EndTagToken)
      end
    end
  end
end
