module Gammo
  class Parser
    # Section 12.2.6.4.6.
    class InBody < InsertionMode
      def text_token(token)
        data = token.data
        node = parser.open_elements.last
        case node.tag
        when Tags::Pre, Tags::Listing
          unless node.first_child
            # ignore a newline at the start of the <pre> block.
            data = data.slice(1..-1) if !data.empty? && data[0] == ?\r
            data = data.slice(1..-1) if !data.empty? && data[0] == ?\n
          end
        end
        data = data.gsub("\x00", '')
        halt true if data.empty?
        parser.reconstruct_active_formatting_elements
        parser.frameset_ok = false if parser.frameset_ok && !data.lstrip.empty?
        parser.add_text(data)
      end

      def start_tag_token(token)
        case token.tag
        when Tags::Html
          halt true if parser.open_elements.any? { |oe| oe.tag == Tags::Template }
          copy_attributes(parser.open_elements[0], token)
        when Tags::Base, Tags::Basefont, Tags::Bgsound, Tags::Link, Tags::Meta,
          Tags::Noframes, Tags::Script, Tags::Style, Tags::Template, Tags::Title
          halt InHead.new(parser).process
        when Tags::Body
          halt true if parser.open_elements.any? { |oe| oe.tag == Tags::Template }
          if parser.open_elements.length >= 2
            body = parser.open_elements[1]
            if body.instance_of?(Node::Element) && body.tag == Tags::Body
              parser.frameset_ok = false
              copy_attributes(body, parser.token)
            end
          end
        when Tags::Frameset
          if !parser.frameset_ok || parser.open_elements.length < 2 || parser.open_elements[1].tag != Tags::Body
            # ignore the token
            halt true
          end
          body = parser.open_elements[1]
          body.parent.remove_child(body) if body.parent
          parser.open_elements = parser.open_elements.slice(0, 1)
          parser.add_element
          parser.insertion_mode = InFrameset
          halt true
        when Tags::Address, Tags::Article, Tags::Aside, Tags::Blockquote,
          Tags::Center, Tags::Dialog, Tags::Details, Tags::Dir, Tags::Div,
          Tags::Dl, Tags::Fieldset, Tags::Figcaption, Tags::Figure,
          Tags::Footer, Tags::Header, Tags::Hgroup, Tags::Main, Tags::Menu,
          Tags::Nav, Tags::Ol, Tags::P, Tags::Section, Tags::Summary, Tags::Ul
          parser.pop_until(BUTTON_SCOPE, Tags::P)
          parser.add_element
        when Tags::H1, Tags::H2, Tags::H3, Tags::H4, Tags::H5, Tags::H6
          parser.pop_until(BUTTON_SCOPE, Tags::P)
          node = parser.top
          case node.tag
          when Tags::H1, Tags::H2, Tags::H3, Tags::H4, Tags::H5, Tags::H6
            parser.open_elements.pop
          end
          parser.add_element
        when Tags::Pre, Tags::Listing
          parser.pop_until(BUTTON_SCOPE, Tags::P)
          parser.add_element
          parser.frameset_ok = false
        when Tags::Form
          # ignore the token.
          halt true if parser.form && !parser.open_elements.any? { |oe| oe.tag == Tags::Template }
          parser.pop_until(BUTTON_SCOPE, Tags::P)
          parser.add_element
          parser.form = parser.top unless parser.open_elements.any? { |oe| oe.tag == Tags::Template }
        when Tags::Li
          parser.frameset_ok = false
          parser.open_elements.reverse_each_with_index do |open_element, index|
            case open_element.tag
            when Tags::Li then parser.open_elements = parser.open_elements.slice(0, index)
            when Tags::Address, Tags::Div, Tags::P then next
            else
              next unless parser.special_element?(open_element)
            end
            break
          end
          parser.pop_until(BUTTON_SCOPE, Tags::P)
          parser.add_element
        when Tags::Dd, Tags::Dt
          parser.frameset_ok = false
          parser.open_elements.reverse_each_with_index do |open_element, index|
            case open_element.tag
            when Tags::Dd, Tags::Dt then parser.open_elements = parser.open_elements.slice(0, index)
            when Tags::Address, Tags::Div, Tags::P then next
            else
              next unless parser.special_element?(open_element)
            end
            break
          end
          parser.pop_until(BUTTON_SCOPE, Tags::P)
          parser.add_element
        when Tags::Plaintext
          parser.pop_until BUTTON_SCOPE, Tags::P
          parser.add_element
        when Tags::Button
          parser.pop_until DEFAULT_SCOPE, Tags::Button
          parser.reconstruct_active_formatting_elements
          parser.add_element
          parser.frameset_ok = false
        when Tags::A
          parser.active_formatting_elements.reverse_each do |afe|
            break if afe.is_a?(Node::ScopeMarker)
            next unless afe.instance_of?(Node::Element) && afe.tag == Tags::A
            adoption_agency_for_end_tag_formatting(Tags::A, "a")
            parser.open_elements.delete(afe)
            parser.active_formatting_elements.delete(afe)
            break
          end
          parser.reconstruct_active_formatting_elements
          parser.add_formatting_element
        when Tags::B, Tags::Big, Tags::Code, Tags::Em, Tags::Font, Tags::I,
          Tags::S, Tags::Small, Tags::Strike, Tags::Strong, Tags::Tt, Tags::U
          parser.reconstruct_active_formatting_elements
          parser.add_formatting_element
        when Tags::Nobr
          parser.reconstruct_active_formatting_elements
          if parser.element_in_scope?(DEFAULT_SCOPE, Tags::Nobr)
            adoption_agency_for_end_tag_formatting(Tags::Nobr, "nobr")
            parser.reconstruct_active_formatting_elements
          end
          parser.add_formatting_element
        when Tags::Applet, Tags::Marquee, Tags::Object
          parser.reconstruct_active_formatting_elements
          parser.add_element
          parser.active_formatting_elements << Node::DEFAULT_SCOPE_MARKER
          parser.frameset_ok = false
        when Tags::Table
          parser.pop_until(BUTTON_SCOPE, Tags::P) unless parser.quirks
          parser.add_element
          parser.frameset_ok = false
          parser.insertion_mode = InTable
          halt true
        when Tags::Area, Tags::Br, Tags::Embed, Tags::Img, Tags::Input, Tags::Keygen, Tags::Wbr
          parser.reconstruct_active_formatting_elements
          parser.add_element
          parser.open_elements.pop
          parser.acknowledge_self_closing_tag
          token.attributes.each do |attr|
            # skip setting frameset_ok = false
            halt true if attr.key == 'type' && attr.value.downcase == 'hidden'
          end if token.tag == Tags::Input
          parser.frameset_ok = false
        when Tags::Param, Tags::Source, Tags::Track
          parser.add_element
          parser.open_elements.pop
          parser.acknowledge_self_closing_tag
        when Tags::Hr
          parser.pop_until BUTTON_SCOPE, Tags::P
          parser.add_element
          parser.open_elements.pop
          parser.acknowledge_self_closing_tag
          parser.frameset_ok = false
        when Tags::Image
          token.tag = Tags::Img
          # todo: fixme <img>
          token.data = Tags::Img.to_s
          halt false
        when Tags::Textarea
          parser.add_element
          parser.set_original_insertion_mode
          parser.frameset_ok = false
          parser.insertion_mode = Text
        when Tags::Xmp
          parser.pop_until(BUTTON_SCOPE, Tags::P)
          parser.reconstruct_active_formatting_elements
          parser.frameset_ok = false
          parser.add_element
          parser.set_original_insertion_mode
          parser.insertion_mode = Text
        when Tags::Iframe
          parser.frameset_ok = false
          parser.parse_generic_raw_text_element
        when Tags::Noembed
          parser.parse_generic_raw_text_element
        when Tags::Noscript
          if parser.scripting?
            parser.parse_generic_raw_text_element
            halt true
          end
          parser.reconstruct_active_formatting_elements
          parser.add_element
          parser.tokenizer.next_is_not_raw_text!
        when Tags::Select
          parser.reconstruct_active_formatting_elements
          parser.add_element
          parser.frameset_ok = false
          parser.insertion_mode = InSelect
          halt true
        when Tags::Optgroup, Tags::Option
          parser.open_elements.pop if parser.top.tag == Tags::Option
          parser.reconstruct_active_formatting_elements
          parser.add_element
        when Tags::Rb, Tags::Rtc
          parser.generate_implied_end_tags if parser.element_in_scope?(DEFAULT_SCOPE, Tags::Ruby)
          parser.add_element
        when Tags::Rp, Tags::Rt
          parser.generate_implied_end_tags('rtc') if parser.element_in_scope?(DEFAULT_SCOPE, Tags::Ruby)
          parser.add_element
        when Tags::Math, Tags::Svg
          parser.reconstruct_active_formatting_elements
          parser.adjust_attribute_names(token.attributes, token.tag == Tags::Math ? Parser::MATH_ML_ATTRIBUTE_ADJUSTMENTS : Parser::SVG_ATTRIBUTE_ADJUSTMENTS)
          parser.adjust_foreign_attributes(token.attributes)
          parser.add_element
          parser.top.namespace = token.data
          if parser.has_self_closing_token
            parser.open_elements.pop
            parser.acknowledge_self_closing_tag
          end
          halt true
        when Tags::Caption, Tags::Col, Tags::Colgroup, Tags::Frame, Tags::Head, Tags::Tbody, Tags::Td, Tags::Tfoot, Tags::Th, Tags::Thead, Tags::Tr
          # ignore the token.
        else
          parser.reconstruct_active_formatting_elements
          parser.add_element
        end
      end

      def end_tag_token(token)
        case token.tag
        when Tags::Body
          parser.insertion_mode = AfterBody if parser.element_in_scope?(DEFAULT_SCOPE, Tags::Body)
        when Tags::Html
          halt true unless parser.element_in_scope?(DEFAULT_SCOPE, Tags::Body)
          parser.parse_implied_token(Tokenizer::EndTagToken, Tags::Body, Tags::Body.to_s)
          halt false
        when Tags::Address, Tags::Article, Tags::Aside, Tags::Blockquote,
          Tags::Button, Tags::Center, Tags::Dialog, Tags::Details, Tags::Dir,
          Tags::Div, Tags::Dl, Tags::Fieldset, Tags::Figcaption, Tags::Figure,
          Tags::Footer, Tags::Header, Tags::Hgroup, Tags::Listing, Tags::Main,
          Tags::Menu, Tags::Nav, Tags::Ol, Tags::Pre, Tags::Section,
          Tags::Summary, Tags::Ul
          parser.pop_until(DEFAULT_SCOPE, token.tag)
        when Tags::Form
          if parser.open_elements.any? { |oe| oe.tag == Tags::Template }
            index = parser.index_of_element_in_scope(DEFAULT_SCOPE, Tags::Form)
            # ignore the token.
            halt true if index == -1
            parser.generate_implied_end_tags
            # ignore the token.
            halt true if parser.open_elements[index].tag != Tags::Form
            parser.pop_until(DEFAULT_SCOPE, Tags::Form)
          else
            node = parser.form
            parser.form = nil
            index = parser.index_of_element_in_scope(DEFAULT_SCOPE, Tags::Form)
            # ignore the token.
            halt true if node == nil || index == -1 || parser.open_elements[index] != node
            parser.generate_implied_end_tags
            parser.open_elements.delete(node)
          end
        when Tags::P
          parser.parse_implied_token(Tokenizer::StartTagToken, Tags::P, Tags::P.to_s) unless parser.element_in_scope?(BUTTON_SCOPE, Tags::P)
          parser.pop_until(BUTTON_SCOPE, Tags::P)
        when Tags::Li
          parser.pop_until(LIST_ITEM_SCOPE, Tags::Li)
        when Tags::Dd, Tags::Dt
          parser.pop_until(DEFAULT_SCOPE, token.tag)
        when Tags::H1, Tags::H2, Tags::H3, Tags::H4, Tags::H5, Tags::H6
          parser.pop_until(DEFAULT_SCOPE, Tags::H1, Tags::H2, Tags::H3, Tags::H4, Tags::H5, Tags::H6)
        when Tags::A, Tags::B, Tags::Big, Tags::Code, Tags::Em, Tags::Font,
          Tags::I, Tags::Nobr, Tags::S, Tags::Small, Tags::Strike,
          Tags::Strong, Tags::Tt, Tags::U
          adoption_agency_for_end_tag_formatting(token.tag, token.data)
        when Tags::Applet, Tags::Marquee, Tags::Object
          parser.clear_active_formatting_elements if parser.pop_until(DEFAULT_SCOPE, token.tag)
        when Tags::Br
          # FIXME
          parser.token = Tokenizer::StartTagToken.new(token.data, tag: token.tag)
          halt false
        when Tags::Template
          halt InHead.new(parser).process
        else
          adoption_agency_for_end_tag_formatting(token.tag, token.data)
        end
      end

      def comment_token(token)
        parser.add_child Node::Comment.new(data: token.data)
      end

      def error_token(token)
        if parser.template_stack.length > 0
          parser.insertion_mode = InTemplate
          halt false
        else
          parser.open_elements.any? do |oe|
            case oe.tag
            when Tags::Dd, Tags::Dt, Tags::Li, Tags::Optgroup, Tags::Option, Tags::P,
              Tags::Rb, Tags::Rp, Tags::Rt, Tags::Rtc, Tags::Tbody, Tags::Td, Tags::Tfoot,
              Tags::Th, Tags::Thead, Tags::Tr, Tags::Body, Tags::Html
            else
              halt true
            end
          end
          halt true
        end
      end

      def default(_)
        halt true
      end

      # Implements "adoption agency" algorithm.
      # https://html.spec.whatwg.org/multipage/syntax.html#adoptionAgency
      # @!visibility private
      def adoption_agency_for_end_tag_formatting(tag, tagname)
        # Step 1-2.
        current = parser.open_elements.last
        if current.data == tagname && parser.active_formatting_elements.index(current) == -1
          parser.open_elements.pop
          return
        end

        # Step 3-5. The outer loop
        8.times do |n|
          # Step 6: Find the formatting element.
          formatting_element = nil
          parser.active_formatting_elements.reverse_each do |afe|
            break if afe.instance_of? Node::ScopeMarker
            if afe.tag == tag
              formatting_element = afe
              break
            end
          end
          unless formatting_element
            adoption_agency_for_end_tag_other(tag, tagname)
            return
          end
          # Step 7. Ignore the tag if formatting element is not in the stack of
          # open elements.
          index = parser.open_elements.index(formatting_element)
          unless index
            parser.active_formatting_elements.delete(formatting_element)
            return
          end
          # Step 8. Ignore the tag if formatting element is not in the scope.
          return unless parser.element_in_scope?(DEFAULT_SCOPE, tag)

          # Step 9. This step is omitted because it's just a parse error but no
          # need to return.

          # Step 10-11. Find the furthest block.
          furthest_block = parser.open_elements.slice(index..-1).find(&parser.method(:special_element?))
          unless furthest_block
            element = parser.open_elements.pop
            element = parser.open_elements.pop while element != formatting_element
            parser.active_formatting_elements.delete(element)
            return
          end

          # Step 12-13. Find the common ancestor and bookmark node.
          common_ancestor = parser.open_elements[index - 1]
          bookmark = parser.active_formatting_elements.index(formatting_element)

          # Step 14. The inner loop. find the last node to reparent.
          last_node = furthest_block
          node = furthest_block
          x = parser.open_elements.index(node)
          # Step 14.1.
          j = 0
          loop do
            # Step 14.2.
            j += 1
            # Step 14.3.
            x -= 1
            node = parser.open_elements[x]
            # Step 14.4.
            break if node == formatting_element

            # Step 14.5. Remove node from the list of active formatting elements if
            # inner loop counter is greater than three and node is in the list of
            # active formatting elements.
            ni = parser.active_formatting_elements.index(node)
            if ni && j > 3
              parser.active_formatting_elements.delete(node)
              # If any element of the list of active formatting elements is removed,
              # we need to take care whether bookmark should be decremented or not.
              # This is because the value of bookmark may exceed the size of the
              # list by removing elements from the list.
              bookmark -= 1 if ni <= bookmark
              next
            end
            # Step 14.6. Continue the next inner loop if node is not in the list of
            # active formatting elements.
            unless parser.active_formatting_elements.include?(node)
              parser.open_elements.delete(node)
              next
            end
            # Step 14.7
            clone = node.clone
            afei = parser.active_formatting_elements.index(node)
            oei = parser.open_elements.index(node)
            raise ParseError, 'bad parser state: expected elements are not found' if !(afei && oei)
            parser.active_formatting_elements[afei] = clone
            parser.open_elements[oei] = clone
            node = clone
            # Step 14.8
            bookmark = (parser.active_formatting_elements.index(node) + 1) || 0 if last_node == furthest_block
            # Step 14.9
            last_node.parent.remove_child(last_node) if last_node.parent
            node.append_child(last_node)
            # Step 14.10
            last_node = node
          end
          # Step 15. Reparent last_node to the common ancestor,
          # or for misnested table nodes, to the foster parent.
          last_node.parent.remove_child(last_node) if last_node.parent
          case common_ancestor.tag
          when Tags::Table, Tags::Tbody, Tags::Tfoot, Tags::Thead, Tags::Tr
            parser.foster_parent(last_node)
          else
            common_ancestor.append_child(last_node)
          end

          # Steps 16-18. Reparent nodes from the furthest block's children
          # to a clone of the formatting element.
          clone = formatting_element.clone
          reparent_children(clone, furthest_block)
          furthest_block.append_child(clone)

          # Step 19. Fix up the list of active formatting elements.
          old_loc = parser.active_formatting_elements.index(formatting_element)
          bookmark -= 1 if old_loc && old_loc < bookmark
          parser.active_formatting_elements.delete(formatting_element)
          parser.active_formatting_elements.insert(bookmark, clone)

          # Step 20. Fix up the stack of open elements.
          parser.open_elements.delete(formatting_element)
          parser.open_elements.insert(parser.open_elements.index(furthest_block) + 1, clone)
        end
      end

      # @!visibility private
      def adoption_agency_for_end_tag_other(tag, tagname)
        parser.open_elements.reverse_each_with_index do |open_element, index|
          if open_element.tag == tag && open_element.data == tagname
            parser.open_elements = parser.open_elements.slice(0, index)
            break
          end
          break if parser.special_element?(open_element)
        end
      end

      # @!visibility private
      def reparent_children(dst, src)
        while child = src.first_child
          src.remove_child(child)
          dst.append_child(child)
        end
      end
    end
  end
end
