require 'gammo/tokenizer/tokens'

module Gammo
  class Parser
    class InsertionMode
      attr_reader :parser

      def initialize(parser)
        @parser  = parser
      end

      def process
        case token = parser.token
        when Tokenizer::ErrorToken          then consume(:error_token)
        when Tokenizer::CharacterToken      then consume(:character_token)
        when Tokenizer::StartTagToken       then consume(:start_tag_token)
        when Tokenizer::EndTagToken         then consume(:end_tag_token)
        when Tokenizer::SelfClosingTagToken then consume(:self_closing_tag_token)
        when Tokenizer::CommentToken        then consume(:comment_token)
        when Tokenizer::DoctypeToken        then consume(:doctype_token)
        else default token
        end
      end

      private

      def halt(consumed)
        throw :halt, consumed
      end

      def consume(name)
        catch :halt do
          token = parser.token
          __send__(name, token) if respond_to?(name)
          default token
        end
      end

      def copy_attributes(dst, src)
        return if src.attributes.length.zero?
        attr = {}
        dst.attributes.each { |dattr| attr[dattr.key] = dattr.value }
        src.attributes.each do |sattr|
          unless attr.has_key?(sattr.key)
            dst.attributes << sattr
            attr[sattr.key] = sattr.value
          end
        end
      end
    end
  end
end

require 'gammo/parser/insertion_mode/in_table'
require 'gammo/parser/insertion_mode/after_head'
require 'gammo/parser/insertion_mode/in_template'
require 'gammo/parser/insertion_mode/in_cell'
require 'gammo/parser/insertion_mode/in_column_group'
require 'gammo/parser/insertion_mode/text'
require 'gammo/parser/insertion_mode/in_body'
require 'gammo/parser/insertion_mode/in_row'
require 'gammo/parser/insertion_mode/initial'
require 'gammo/parser/insertion_mode/before_html'
require 'gammo/parser/insertion_mode/in_table_body'
require 'gammo/parser/insertion_mode/before_head'
require 'gammo/parser/insertion_mode/in_frameset'
require 'gammo/parser/insertion_mode/after_body'
require 'gammo/parser/insertion_mode/after_frameset'
require 'gammo/parser/insertion_mode/in_caption'
require 'gammo/parser/insertion_mode/after_after_body'
require 'gammo/parser/insertion_mode/in_head'
require 'gammo/parser/insertion_mode/in_head_noscript'
require 'gammo/parser/insertion_mode/in_select_in_table'
require 'gammo/parser/insertion_mode/in_select'
