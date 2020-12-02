require 'forwardable'
require 'strscan'
require 'gammo/tags'
require 'gammo/attribute'
require 'gammo/tokenizer/tokens'
require 'gammo/tokenizer/script_scanner'
require 'gammo/tokenizer/escape'

module Gammo
  # Class for implementing HTML5 tokenization algorithm.
  class Tokenizer
    include Escape

    # Represents end-of-string.
    EOS = ErrorToken.new('end of string')

    # Raised if unexpected EOS is found.
    # @!visibility private
    EOSError = Class.new(StandardError)

    attr_accessor :scanner, :raw_tag, :convert_null, :raw

    extend Forwardable
    def_delegators :scanner, :scan, :scan_until, :check, :matched, :unscan

    def initialize(text, context: nil)
      @text          = text
      @scanner       = StringScanner.new(text.force_encoding(Encoding::UTF_8))
      @raw_tag       = context && raw_tag?(context.downcase) ? context.downcase : ''
      @convert_null  = false
      @cdata_allowed = false
      @raw           = false
    end

    def allow_cdata!(b)
      @cdata_allowed = !!b
    end

    def allow_cdata?
      @cdata_allowed
    end

    def previous_token_is_raw_tag?
      !raw_tag.empty?
    end

    def next_token
      return EOS if scanner.eos?
      if previous_token_is_raw_tag? && (token = next_token_for_raw_tag)
        return token
      end
      @raw          = false
      @convert_null = false
      pos = scanner.pos
      buffer = ''.force_encoding(Encoding::ASCII)
      loop do
        break unless byte = scanner.get_byte
        buffer << byte
        next if byte != ?<
        break unless byte = scanner.get_byte
        buffer << byte
        if pos < (scanner.pos - 2)
          scanner.pos -= 2
          buffer = buffer.slice(0, buffer.length - 2)
          return character_token(buffer)
        end
        case byte
        when %r{[a-zA-Z]}
          step_back
          return scan_start_tag
        when ?!           then return scan_markup_declaration
        when ??           then return comment_token(?? + scan_until_close_angle)
        when ?/
          return character_token(buffer) if scanner.eos?
          # "</>" does not generate a token at all. treat this as empty comment token.
          return comment_token('') if scan(/>/)
          # Expects chars like "</a"
          return comment_token(scan_until_close_angle) unless check(/[a-zA-Z]/)
          begin
            tag = scan_tag(need_attribute: false)
          rescue EOSError
            return EOS
          end
          return error_token(pos) if tag.nil?
          return end_tag_token(tag)
        else
          step_back
          buffer = buffer.slice(0, buffer.length - 1)
          next
        end
      end
      return character_token(buffer) if pos < scanner.pos
      EOS
    end

    def next_is_not_raw_text!
      @raw_tag = ''
    end

    private

    def next_token_for_raw_tag
      pos = scanner.pos
      token =
        if raw_tag != 'plaintext'
          scan_raw_or_rcdata
        else
          @raw = true
          character_token(scan_until(/\z/) || '')
        end
      if token && scanner.pos > pos
        @convert_null      = true
        token.convert_null = true
        token.load_data(token.data)
        return token
      end
    end

    def scan_raw_or_rcdata
      if raw_tag == 'script'
        token = scan_script
        @raw     = true
        @raw_tag = ''
        return token
      end
      buffer = ''
      while !scanner.eos?
        ch = scanner.get_byte
        buffer << ch
        break if scanner.eos?
        next if ch != ?<
        ch = scanner.get_byte
        buffer << ch
        break if scanner.eos?
        if ch != ?/
          buffer = buffer.slice(0, buffer.length - 1)
          scanner.unscan
          next
        end
        if scanner.check(%r{#{raw_tag}[>\s\/]}) || scanner.eos?
          buffer = buffer.slice(0..-3)
          scanner.pos -= 2
          break
        end
      end
      @raw = raw_tag != 'textarea' && raw_tag != 'title'
      @raw_tag = ''
      character_token(buffer) unless buffer.empty?
    end

    def scan_script
      character_token(ScriptScanner.new(scanner, raw_tag: raw_tag).scan)
    end

    def scan_start_tag
      begin
        tag = scan_tag(need_attribute: true)
      rescue EOSError
        return EOS
      end
      name = tag.name
      @raw_tag = name.downcase if raw_tag?(name)
      (tag.self_closing? || scanner.string.slice(scanner.pos - 2) == ?/ ? SelfClosingTagToken : StartTagToken).new(
        name,
        tag: Tags.lookup(tag.name),
        attributes: tag.attributes,
      )
    end

    def peek(length:, target: matched)
      target.slice(0, length)
    end

    def step_back
      scanner.pos -= 1
    end

    def scan_tag_attribute_key
      key = scan_until(%r{[=>\s/]})
      return scan_until(/\z/).downcase unless key
      return if key.length < 2
      ch = key.slice(key.length - 1)
      case ch when ?=, ?> then step_back end
      key.slice(0, key.length - 1).downcase
    end

    def scan_tag_attribute_value
      byte = scanner.get_byte
      step_back && return if byte != ?=
      scan_whitespace
      return unless quote = scanner.get_byte
      return if scanner.eos?
      case quote
      when ?>     then step_back && return
      when ?', ?"
        value = scan_until(/#{quote}/) 
        unless value
          scan_until(/\z/)
          raise EOSError, "Couldn't find a token for representing end of the tag" unless byte = scanner.get_byte
        end
        value.slice(0, value.length - 1)
      else
        return quote if scanner.eos?
        return quote + scan_until(/\z/) unless value = scan_until(/[\s>]/)
        step_back if value.end_with?(?>)
        quote + value.slice(0, value.length - 1)
      end
    end

    class Tag
      attr_accessor :name, :attributes, :self_closing

      def initialize(name:, attributes: [], self_closing: false)
        @name         = name
        @attributes   = attributes
        @self_closing = self_closing
      end

      def self_closing?
        !!self_closing
      end
    end

    def scan_tag(need_attribute: false)
      name = scan_until(%r{[\s/>]})
      name =
        if name
          step_back if name.end_with?(?/) || name.end_with?(?>)
          name.slice(0, name.length - 1)
        else
          if buf = scan_until(/\s/)
            step_back
            buf.slice(0, buf.length - 1)
          else
            scan_until(/\z/)
            raise EOSError, "Couldn't find a token for representing end of the tag"
          end
        end
      name = name.downcase
      scan_whitespace
      return Tag.new(name: name) if scanner.eos?
      attrs = []
      while !scan(/>/)
        key = scan_tag_attribute_key
        return Tag.new(name: name, attributes: attrs, self_closing: true) if key == ?/ && scan(/>/)
        next unless key
        break if scanner.eos?
        scan_whitespace
        break if scanner.eos?
        value = scan_tag_attribute_value
        value = unescape(value, in_attribute: true) if value
        break if scanner.eos?
        attrs << Attribute.new(key: key, value: value) if need_attribute
        scan_whitespace
        break if scanner.eos?
      end
      Tag.new(name: name, attributes: attrs, self_closing: false)
    end

    def scan_markup_declaration
      return scan_comment if scan(/--/)
      return scan_doctype if scan(/DOCTYPE/i)
      if allow_cdata? && (cdata = scan_cdata)
        self.convert_null = true
        cdata
      else
        comment_token(scan_until_close_angle)
      end
    end

    def scan_until_close_angle
      text = scan_until(/>/)
      text ? text.slice(0, text.length - 1) : scan_until(/\z/)
    end

    def scan_doctype
      scan_whitespace
      return error_token(scanner.pos) if scanner.eos?
      doctype_token(scan_until_close_angle)
    end

    def scan_comment
      count = 2
      buffer = ''
      loop do
        unless byte = scanner.get_byte
          count = 2 if count > 2
          buffer = buffer.slice(0, buffer.length - count)
          break
        end
        buffer << byte
        case byte
        when ?-
          count += 1
          next
        when ?>
          if count >= 2
            # "-->"
            buffer = buffer.slice(0, buffer.length - 3)
            break
          end
        when ?!
          if count >= 2
            break unless byte = scanner.get_byte
            # "--!>"
            if byte == ?>
              # no need to count ">" as it's not appended to the buffer.
              buffer = buffer.slice(0, buffer.length - 3)
              break
            end
          end
        end
        count = 0
      end
      comment_token(buffer)
    end

    def scan_whitespace
      scan(/[\s]+/)
    end

    def scan_cdata
      return unless scan(/\[CDATA\[/)
      brackets = 0
      buffer = ''
      loop do
        byte = scanner.get_byte
        return character_token(buffer) unless byte
        buffer << byte
        case byte
        when ?]
          brackets += 1
        when ?>
          if brackets >= 2
            buffer = buffer.slice(0, buffer.length - ']]>'.length)
            break
          end
          brackets = 0
        else
          brackets = 0
        end
      end
      character_token(buffer)
    end

    RAW_TAGS = ['iframe', 'noembed', 'noframes', 'noscript', 'plaintext', 'script', 'style', 'textarea', 'title', 'xmp'].freeze
    RAW_TAGS_UNION = %r{#{RAW_TAGS.join(?|)}}

    def raw_tag?(name)
      RAW_TAGS.include?(name)
    end

    def character_token(text)
      CharacterToken.new(text, raw: raw, convert_null: convert_null)
    end

    def error_token(pos)
      ErrorToken.new("unexpected token, #{scanner.string.slice(pos..scanner.pos)}")
    end

    def end_tag_token(tag)
      EndTagToken.new(tag.name, tag: Tags.lookup(tag.name), attributes: tag.attributes)
    end

    def comment_token(text)
      CommentToken.new(text, raw: raw, convert_null: convert_null)
    end

    def doctype_token(text)
      DoctypeToken.new(text, raw: raw, convert_null: convert_null)
    end
  end
end
