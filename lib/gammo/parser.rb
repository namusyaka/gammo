require 'delegate'
require 'gammo/node'
require 'gammo/tags'
require 'gammo/tokenizer'
require 'gammo/parser/node_stack'
require 'gammo/parser/foreign'
require 'gammo/parser/constants'
require 'gammo/parser/insertion_mode_stack'

module Gammo
  # Class for parsing an HTML input and building an HTML tree.
  class Parser
    require 'gammo/parser/insertion_mode'

    include Foreign
    include Constants

    # Raised if anything goes wrong while parsing an HTML.
    ParseError = Class.new(ArgumentError)

    # Default scope stop tags defined in 12.2.4.2.
    # https://html.spec.whatwg.org/multipage/parsing.html#the-stack-of-open-elements
    # @!visibility private
    DEFAULT_SCOPE_STOP_TAGS = {
      nil    => [Tags::Applet, Tags::Caption, Tags::Html, Tags::Table, Tags::Td,
              Tags::Th, Tags::Marquee, Tags::Object, Tags::Template],
      'math' => [Tags::AnnotationXml, Tags::Mi, Tags::Mn, Tags::Mo, Tags::Ms,
                 Tags::Mtext],
      'svg'  => [Tags::Desc, Tags::ForeignObject, Tags::Title]
    }.freeze

    # Scope constants defined in 12.2.4.2.
    # https://html.spec.whatwg.org/multipage/parsing.html#the-stack-of-open-elements

    # @!visibility private
    DEFAULT_SCOPE = 0

    # @!visibility private
    LIST_ITEM_SCOPE = 1

    # @!visibility private
    BUTTON_SCOPE = 2

    # @!visibility private
    TABLE_SCOPE = 3

    # @!visibility private
    TABLE_ROW_SCOPE = 4

    # @!visibility private
    TABLE_BODY_SCOPE = 5

    # @!visibility private
    SELECT_SCOPE = 6

    # Tokenizer for parsing each token.
    # @!visibility private
    attr_accessor :tokenizer, :token

    # The insertion mode is a state variable that controls the primary operation
    # of the tree construction stage.
    # https://html.spec.whatwg.org/multipage/parsing.html#the-insertion-mode
    # @!visibility private
    attr_accessor :insertion_mode

    # The original insertion mode is set to this accessor, defined in 12.2.4.1.
    # When the insertion mode is switched to "text" or "in table text",
    # the original insertion mode is also set. This is the insertion mode to
    # which the tree construction stage will return.
    # https://html.spec.whatwg.org/multipage/parsing.html#the-insertion-mode
    # @!visibility private
    attr_accessor :original_insertion_mode

    # `template_stack` represents the stack of template insertion modes.
    # Defined in 12.4.2.1.
    # @!visibility private
    attr_accessor :template_stack

    # The stack of open elements, defined in 12.2.4.2.
    # https://html.spec.whatwg.org/multipage/parsing.html#the-stack-of-open-elements
    # @!visibility private
    attr_accessor :open_elements

    # The list of active formatting elements defined in 12.2.4.3.
    # https://html.spec.whatwg.org/multipage/parsing.html#the-list-of-active-formatting-elements
    # @!visibility private
    attr_accessor :active_formatting_elements

    # The element pointers defined in 12.2.4.4.
    # https://html.spec.whatwg.org/multipage/parsing.html#other-parsing-state-flags
    attr_accessor :head, :form

    # Other parsing state flags defined in 12.2.4.5.
    # https://html.spec.whatwg.org/multipage/parsing.html#other-parsing-state-flags
    attr_accessor :scripting, :frameset_ok
    alias_method :scripting?, :scripting
    alias_method :frameset_ok?, :frameset_ok

    # Document root element
    attr_accessor :document

    # Self-closing flag defined in 12.2.5.
    # Self-closing tags like <img /> are treated as start tag token, except
    # `has_self_closing_token` is set while they are being proceeded.
    # @!visibility private
    attr_accessor :has_self_closing_token

    # Quirks flag is defined in 12.2.5.
    # quirks flag is whether the parser is operating in the "force-quirks" mode.
    # @!visibility private
    attr_accessor :quirks

    # `foster_parenting` is set to true if a new element should be inserted
    # according to the foster parenting rule defined in 12.2.6.1.
    # https://html.spec.whatwg.org/multipage/parsing.html#creating-and-inserting-nodes
    # @!visibility private
    attr_accessor :foster_parenting

    # The context element is for use in parsing an HTML fragment, defined in
    # 12.2.4.2.
    # https://html.spec.whatwg.org/multipage/parsing.html#parsing-html-fragments
    attr_accessor :context

    # `input` is the original input text.
    # @!visibility private
    attr_reader :input

    # Constructs a parser for parsing an HTML input.
    # @param [String] input
    # @param [TrueClass, FalseClass] scripting
    # @param [TrueClass, FalseClass] frameset_ok
    # @param [InsertionMode] insertion_mode
    # @param [Gammo::Node] context
    # @return [Gammo::Parser]
    def initialize(input, scripting: true, frameset_ok: true, insertion_mode: Initial, context: nil)
      @input                      = input
      @scripting                  = scripting
      @frameset_ok                = frameset_ok
      @context                    = context
      @insertion_mode             = insertion_mode
      @token                      = nil
      @tokenizer                  = Tokenizer.new(input)
      @document                   = Node::Document.new
      @open_elements              = Parser::NodeStack.new([])
      @active_formatting_elements = Parser::NodeStack.new([])
      @template_stack             = InsertionModeStack.new([])
      @foster_parenting           = false
      @has_self_closing_token     = false
      @quirks                     = false
      @form                       = nil
      @head                       = nil
    end

    # Parses the current input and builds HTML tree from it.
    # @raise [Gammo::ParseError] Raised if the parser gets error while parsing.
    # @return [Gammo::Node::Document, nil]
    def parse
      while self.token != Tokenizer::EOS
        # CDATA sections are allowed only in foreign content.
        node = open_elements.last
        tokenizer.allow_cdata!(node && node.namespace)
        self.token = tokenizer.next_token
        return if self.token.instance_of?(Tokenizer::ErrorToken) && self.token != Tokenizer::EOS
        parse_current_token
        break if self.token == Tokenizer::EOS
      end
      self.document
    end

    # Always returns false.
    # @return [FalseClass]
    # @!visibility private
    def fragment?
      false
    end

    # Returns true if given node is matched with any special elements
    # defined in 12.2.4.2.
    # https://html.spec.whatwg.org/multipage/syntax.html#the-stack-of-open-elements
    #
    # @param [Gammo::Node] node
    # @return [TrueClass, FalseClass]
    # @see Gammo::Parser::Constants::SPECIAL_ELEMENTS
    # @!visibility private
    def special_element?(node)
      case node.namespace
      when nil, 'html'
        SPECIAL_ELEMENTS[node.data]
      when 'math'
        case node.data
        when 'mi', 'mo', 'mn', 'ms', 'mtext', 'annotation-xml'
          true
        end
      when 'svg'
        case node.data
        when 'foreignObject', 'desc', 'title'
          true
        end
      end
    end

    # @!visibility private
    def parse_implied_token(tok, tag, data)
      real_token, self_closing = token, has_self_closing_token
      @token = tok.new(data, tag: tag)
      @has_self_closing_token = false
      parse_current_token
      @token, @has_self_closing_token = real_token, self_closing
    end

    # @!visibility private
    def pop_until(scope, *match_tags)
      index = index_of_element_in_scope(scope, *match_tags)
      if index != -1
        @open_elements = open_elements.slice(0, index)
        return true
      end
      false
    end

    # @!visibility private
    def index_of_element_in_scope(scope, *match_tags)
      open_elements.reverse_each_with_index do |open_element, index|
        tag = open_element.tag
        unless open_element.namespace
          return index if match_tags.include?(tag)
          case scope
          when DEFAULT_SCOPE
            # no op
          when LIST_ITEM_SCOPE
            return -1 if tag == Tags::Ol || tag == Tags::Ul
          when BUTTON_SCOPE
            return -1 if tag == Tags::Button
          when TABLE_SCOPE
            return -1 if tag == Tags::Html || tag == Tags::Table || tag == Tags::Template
          when SELECT_SCOPE
            return -1 if tag == Tags::Optgroup && tag == Tags::Option
          else
            raise ParseError, 'unreachable parsing error, please report to github'
          end
        end
        case scope
        when DEFAULT_SCOPE, LIST_ITEM_SCOPE, BUTTON_SCOPE
          return -1 if DEFAULT_SCOPE_STOP_TAGS[open_element.namespace].include?(tag)
        end
      end
      -1
    end

    # @!visibility private
    def parse_generic_raw_text_element
      add_element
      @original_insertion_mode = insertion_mode
      @insertion_mode = Text
    end

    # 12.2.4.2
    # @!visibility private
    def adjusted_current_node
      return context if open_elements.length == 1 && fragment? && context
      open_elements.last
    end

    # @!visibility private
    def element_in_scope?(scope, *match_tags)
      index_of_element_in_scope(scope, *match_tags) != -1
    end

    # @!visibility private
    def clear_stack_to_context(scope)
      open_elements.reverse_each_with_index do |open_element, index|
        tag = open_element.tag
        case scope
        when TABLE_SCOPE
          if tag == Tags::Html || tag == Tags::Table || tag == Tags::Template
            @open_elements = open_elements.slice(0, index + 1)
            return
          end
        when TABLE_ROW_SCOPE
          if tag == Tags::Html || tag == Tags::Tr || tag == Tags::Template
            @open_elements = open_elements.slice(0, index + 1)
            return
          end
        when TABLE_BODY_SCOPE
          if tag == Tags::Html || tag == Tags::Tbody || tag == Tags::Tfoot || tag == Tags::Thead || tag == Tags::Template
            @open_elements = open_elements.slice(0, index + 1)
            return
          end
        else
          raise ParseError, 'unreachable parsing error, please report to github'
        end
      end
    end

    # @!visibility private
    def generate_implied_end_tags(*exceptions)
      index = open_elements.reverse_each_with_index do |node, i|
        break index unless node.instance_of? Node::Element
        case node.tag
        when Tags::Dd, Tags::Dt, Tags::Optgroup, Tags::Option, Tags::P, Tags::Rb, Tags::Rp, Tags::Rt, Tags::Rtc
          break i if exceptions.include?(node.data)
          next
        end
        break i
      end
      @open_elements = open_elements.slice(0, index + 1)
    end

    # @!visibility private
    def add_child(node)
      should_foster_parent? ? foster_parent(node) : top.append_child(node)
      open_elements << node if node.instance_of?(Node::Element)
    end

    # @!visibility private
    def top
      open_elements.last || document
    end

    # @!visibility private
    def add_element
      elm = Node::Element.new(tag: token.tag, data: token.data)
      elm.attributes = Attributes.new(token.attributes, owner_element: elm)
      add_child(elm)
    end

    # @!visibility private
    def should_foster_parent?
      return false unless foster_parenting
      case top.tag
      when Tags::Table, Tags::Tbody, Tags::Tfoot, Tags::Thead, Tags::Tr
        return true
      end
      false
    end

    # @!visibility private
    def foster_parent(node)
      i = 0
      table = open_elements.reverse_each_with_index do |open_element, index|
        if open_element.tag == Tags::Table
          i = index
          break open_element 
        end
      end
      j = 0
      template = open_elements.reverse_each_with_index do |open_element, index|
        if open_element.tag == Tags::Template
          j = index
          break open_element
        end
      end
      return template.append_child(node) if template && (!table || j > i)
      parent = table ? table.parent : open_elements[0]
      parent = open_elements[i - 1] unless parent
      prev = table ? table.previous_sibling : parent.last_child
      if prev && prev.instance_of?(Node::Text) && node.instance_of?(Node::Text)
        prev.data += node.data
        return
      end
      parent.insert_before(node, table)
    end

    # @!visibility private
    def add_text(text)
      return if text.empty?
      return foster_parent(Node::Text.new(data: text)) if should_foster_parent?
      t = top
      node = t.last_child
      if node && node.instance_of?(Node::Text)
        node.data += text
        return
      end
      add_child Node::Text.new(data: text)
    end

    # @!visibility private
    def add_formatting_element
      tag, attrs = token.tag, token.attributes
      add_element
      identical_elements = 0
      # todo
      continued_finding = false
      active_formatting_elements.reverse_each_with_index do |node, i|
        continued_finding = false
        break if node.instance_of?(Node::ScopeMarker)
        next unless node.instance_of?(Node::Element)
        next if node.namespace || node.tag != tag || node.attributes.length != attrs.length
        # compare attrs
        node.attributes.each.with_index do |a, j|
          continue_comparing = false
          attrs.each_with_index do |b, k|
            if a.key == b.key && a.namespace == b.namespace && a.value == b.value
              continue_comparing = true
              break
            end
          end
          next if continue_comparing
          continued_finding = true
          break if continued_finding
        end
        next if continued_finding
        identical_elements += 1
        active_formatting_elements.delete(node) if identical_elements >= 3
      end

      active_formatting_elements << open_elements.last
    end

    # @!visibility private
    def clear_active_formatting_elements
      loop do
        node = active_formatting_elements.pop
        return if active_formatting_elements.length.zero? || node.instance_of?(Node::ScopeMarker)
      end
    end

    # @!visibility private
    def reconstruct_active_formatting_elements
      return unless node = active_formatting_elements.last
      return if node.instance_of?(Node::ScopeMarker) || open_elements.index(node)
      i = active_formatting_elements.length - 1
      until node.is_a?(Node::ScopeMarker) || open_elements.index(node)
        if i.zero?
          i = -1
          break
        end
        i -= 1
        node = active_formatting_elements[i]
      end
      loop do
        i += 1
        cloned = active_formatting_elements[i].clone
        add_child(cloned)
        active_formatting_elements[i] = cloned
        break if i == active_formatting_elements.length - 1
      end
    end

    # @!visibility private
    def acknowledge_self_closing_tag
      @has_self_closing_token = false
    end

    # @!visibility private
    def set_original_insertion_mode
      raise 'bad parser state: original im was set twice' if original_insertion_mode
      @original_insertion_mode = @insertion_mode
    end

    # @!visibility private
    def reset_insertion_mode
      open_elements.reverse_each_with_index do |open_element, index|
        node = open_element
        last = index.zero?
        node = self.context if last && self.context
        case node.tag
        when Tags::Select
          unless last
            ancestor = node
            first = open_elements[0]
            while ancestor != first
              ancestor = open_elements[open_elements.index(ancestor) - 1]
              case ancestor.tag
              when Tags::Template
                @insertion_mode = InSelect
                return
              when Tags::Table
                @insertion_mode = InSelectInTable
                return
              end
            end
          end
          @insertion_mode = InSelect
        when Tags::Td, Tags::Th
          # remove this divergence from the HTML5 spec.
          @insertion_mode = InCell
        when Tags::Tr
          @insertion_mode = InRow
        when Tags::Tbody, Tags::Thead, Tags::Tfoot
          @insertion_mode = InTableBody
        when Tags::Caption
          @insertion_mode = InCaption
        when Tags::Colgroup
          @insertion_mode = InColumnGroup
        when Tags::Table
          @insertion_mode = InTable
        when Tags::Template
          # remove this divergence from the HTML5 spec.
          next if node.namespace
          @insertion_mode = template_stack.last
        when Tags::Head
          # remove this divergence from the HTML5 spec.
          @insertion_mode = InHead
        when Tags::Body
          @insertion_mode = InBody
        when Tags::Frameset
          @insertion_mode = InFrameset
        when Tags::Html
          @insertion_mode = @head ? AfterHead : BeforeHead
        else
          if last
            @insertion_mode = InBody
            return
          end
          next
        end
        return
      end
    end

    # @!visibility private
    def parse_current_token
      if token.instance_of? Tokenizer::SelfClosingTagToken
        self.has_self_closing_token = true
        self.token = Tokenizer::StartTagToken.new(token.data, tag: token.tag, attributes: token.attributes)
      end
      consumed = false
      until consumed
        consumed =
          in_foreign_content? ? parse_foreign_content : insertion_mode.new(self).process
      end
      self.has_self_closing_token = false if self.has_self_closing_token
    end
  end
end
