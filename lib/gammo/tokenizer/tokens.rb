require 'gammo/tokenizer/escape'

module Gammo
  class Tokenizer
    class BaseToken
      attr_accessor :attributes, :data, :tag

      def initialize(data = '', attributes: [], tag: nil)
        @data       = data
        @attributes = attributes
        @tag        = tag
      end

      def concat(s)
        data << s
      end

      def to_s
        s = "<#{self.class}"
        members = []
        members << "tag=\"#{tag}\"" if tag
        members << "data=\"#{data}\"" if data
        members << "attributes=\"#{attributes}\"" if attributes && !attributes.empty?
        "<#{self.class} #{members.join(' ')}>"
      end
    end

    class EscapedToken < BaseToken
      include Escape

      NULL        = ?\x00.freeze
      REPLACEMENT = "\ufffd".freeze

      attr_accessor :convert_null, :raw

      def initialize(data = nil, raw: false, convert_null: false, **options)
        super(data, **options)
        @raw          = raw
        @convert_null = convert_null
        load_data(data)
      end

      def load_data(raw_data)
        unless raw_data
          @data = nil
          return
        end
        raw_data = convert_newlines(raw_data).force_encoding(Encoding::UTF_8)
        raw_data = raw_data.gsub(%r{#{NULL}}, REPLACEMENT) if should_convert_null?(raw_data)
        @data = require_raw_data? ? raw_data : unescape(raw_data, in_attribute: false)
      end

      private

      alias_method :convert_null?, :convert_null
      alias_method :require_raw_data?, :raw

      def should_convert_null?(data)
        data && (convert_null? || self.class == CommentToken) && data.include?(NULL)
      end

      def convert_newlines(s)
        s.gsub(/(\r\n|\r)/, ?\n)
      end
    end

    ErrorToken          = Class.new(BaseToken)
    CharacterToken      = Class.new(EscapedToken)
    StartTagToken       = Class.new(BaseToken)
    EndTagToken         = Class.new(BaseToken)
    SelfClosingTagToken = Class.new(BaseToken)
    CommentToken        = Class.new(EscapedToken)
    DoctypeToken        = Class.new(EscapedToken)
  end
end
