class Gammo::CSSSelector::Parser

token T_COMMA
      T_PLUS
      T_MINUS
      T_HYPHEN
      T_DIMENSION
      T_NUMBER
      T_STRING
      T_IDENT
      T_NOT
      T_RBRACK
      T_HASH
      T_S
      T_GREATER
      T_TILDE
      T_DOT
      T_PIPE
      T_ASTERISK
      T_LBRACK
      T_PREFIXMATCH
      T_SUFFIXMATCH
      T_SUBSTRINGMATCH
      T_EQUAL
      T_INCLUDES
      T_DASHMATCH
      T_COLON
      T_FUNCTION
      T_RPAREN
      T_ASTERISK

start selectors_group

rule
  optional_whitespaces:
    | repeatable_whitespaces

  repeatable_whitespaces:
    T_S
    | repeatable_whitespaces T_S

  # selectors_group: selector [ COMMA S* selector ]*
  selectors_group:
    repeatable_selectors { result = val[0] }
  
  repeatable_selectors:
    selector {
      result = AST::SelectorsGroup.new
      result << val[0]
    }
    | repeatable_selectors optional_whitespaces T_COMMA optional_whitespaces selector {
      result = val[0]
      result << val[4]
    }

  # selector: simple_selector_sequence [ combinator simple_selector_sequence ]*
  selector:
    repeatable_simple_selector_sequence

  # combinators can be surrounded by whitespace
  # combinator: PLUS S* | GREATER S* | TILDE S* | S+
  combinator:
    optional_whitespaces T_PLUS optional_whitespaces { result = :next_sibling }
    | optional_whitespaces T_GREATER optional_whitespaces { result = :child }
    | optional_whitespaces T_TILDE optional_whitespaces { result = :subsequent_sibling }
    | repeatable_whitespaces { result = :descendant }

  repeatable_simple_selector_sequence:
    simple_selector_sequence {
      result = val[0]
    }
    | repeatable_simple_selector_sequence combinator simple_selector_sequence {
      result = val[0]
      result.combine(AST::Combinator.fetch(val[1]).new(val[2]))
    }

  # simple_selector_sequence:
  # [ type_selector | universal ]
  #   [ HASH | class | attrib | pseudo | negation ]*
  # | [ HASH | class | attrib | pseudo | negation ]+
  simple_selector_sequence:
    type_selector
    | universal
    | type_selector repeatable_selector_operators {
      val[0].selectors.concat(val[1])
      result = val[0]
    }
    | universal repeatable_selector_operators {
      val[0].selectors.concat(val[1])
      result = val[0]
    }
    | repeatable_selector_operators {
      any = AST::Selector::Universal.new
      any.selectors.concat(val[0])
      result = any
    }

  repeatable_selector_operators:
    selector_operators { result = [val[0]] }
    | repeatable_selector_operators selector_operators { result = val[0] << val[1] }

  selector_operators:
    hash
    | class
    | attrib
    | pseudo
    | negation

  # type_selector: [ namespace_prefix ]? element_name
  type_selector:
    element_name { result = AST::Selector::Type.new(element_name: val[0]) }
    | namespace_prefix element_name  { result = AST::Selector::Type.new(element_name: val[1], namespace_prefix: val[0]) }

  # namespace_prefix: [ IDENT | '*' ]? '|'
  namespace_prefix: 
    T_PIPE { result = val[0] }
    | T_IDENT T_PIPE { result = val[0] }
    | T_ASTERISK T_PIPE { result = val[1] }

  # element_name: IDENT
  element_name: T_IDENT { result = val[0] }

  # universal: [ namespace_prefix ]? '*'
  universal:
    namespace_prefix T_ASTERISK { result = AST::Selector::Universal.new(namespace_prefix: val[0]) }
    | T_ASTERISK { result = AST::Selector::Universal.new }

  # class: '.' IDENT
  class: T_DOT T_IDENT { result = AST::Selector::Class.new(val[1]) }

  # attrib: '[' S* [ namespace_prefix ]? IDENT S*
  #  [ [ PREFIXMATCH |
  #      SUFFIXMATCH |
  #      SUBSTRINGMATCH |
  #      '=' |
  #      INCLUDES |
  #      DASHMATCH ] S* [ IDENT | STRING ] S*
  #  ]? ']'
  attrib:
    T_LBRACK optional_whitespaces namespace_prefix T_IDENT optional_whitespaces optional_attrib_clause T_RBRACK {
      op, value = val[4]
      result = AST::Selector::Attrib.fetch(op).new(key: val[2], value: value, namespace_prefix: val[2])
    }
    | T_LBRACK optional_whitespaces T_IDENT optional_whitespaces optional_attrib_clause T_RBRACK {
      op, value = val[4]
      result = AST::Selector::Attrib.fetch(op).new(key: val[2], value: value)
    }

  optional_attrib_clause:
    | attrib_operators optional_whitespaces T_IDENT optional_whitespaces { result = [val[0], val[2]] }
    | attrib_operators optional_whitespaces T_STRING optional_whitespaces { result = [val[0], val[2]] }

  attrib_operators:
    T_PREFIXMATCH      { result = :prefix_match }
    | T_SUFFIXMATCH    { result = :suffix_match }
    | T_SUBSTRINGMATCH { result = :substring_match }
    | T_EQUAL          { result = :equal }
    | T_INCLUDES       { result = :includes }
    | T_DASHMATCH      { result = :dash_match }

  # pseudo: ':' ':'? [ IDENT | functional_pseudo ]
  pseudo:
    T_COLON optional_colon T_IDENT { result = AST::Selector::Pseudo.fetch(val[2]).new }
    | T_COLON optional_colon functional_pseudo { result = val[2] }

  optional_colon: | T_COLON

  # functional_pseudo: FUNCTION S* expression ')'
  functional_pseudo:
    T_FUNCTION optional_whitespaces repeatable_expressions T_RPAREN { result = AST::Selector::Pseudo.fetch(val[0].slice(0..-2)).new(val[2]) }

  # expression: [ [ PLUS | '-' | DIMENSION | NUMBER | STRING | IDENT ] S* ]+
  expression:
    T_PLUS | T_MINUS | T_HYPHEN | T_DIMENSION | T_NUMBER | T_STRING | T_IDENT { result = val[0] }

  repeatable_expressions:
    expression optional_whitespaces { result = [val[0]] }
    | repeatable_expressions expression optional_whitespaces {
      val[0] << val[1]
      result = val[0]
    }

  # negation: NOT S* negation_arg S* ')'
  negation:
    T_NOT optional_whitespaces negation_arg optional_whitespaces T_RPAREN { result = AST::Selector::Negation.new(val[2]) }

  # negation_arg: type_selector | universal | HASH | class | attrib | pseudo
  negation_arg:
    type_selector | universal | hash | class | attrib | pseudo

  hash:
    T_HASH { result = AST::Selector::ID.new(val[0]) }

end

---- inner

  NONASCII = /[^\0-\177]/
  UNICODE  = /\\[0-9a-f]{1,6}(\r\n|[ \n\r\t\f])?/
  ESCAPE   = /#{UNICODE}|\\[^\n\r\f0-9a-f]/
  NMCHAR   = /[_a-z0-9-]|#{NONASCII}|#{ESCAPE}/
  NMSTART  = /[_a-z]|#{NONASCII}|#{ESCAPE}/
  NUM      = /[0-9]+|[0-9]*\.[0-9]+/
  NAME     = /#{NMCHAR}+/
  IDENT    = /[-]?#{NMSTART}#{NMCHAR}*/
  NL       = /\n|\r\n|\r|\f/
  STRING1  = /\"([^\n\r\f\\"]|\\#{NL}|#{NONASCII}|#{ESCAPE})*\"/
  STRING2  = /\'([^\n\r\f\\']|\\#{NL}|#{NONASCII}|#{ESCAPE})*\'/
  STRING   = /#{STRING1}|#{STRING2}/
  INVALID1 = /\"([^\n\r\f\\"]|\\#{NL}|#{NONASCII}|#{ESCAPE})*/
  INVALID2 = /\'([^\n\r\f\\']|\\#{NL}|#{NONASCII}|#{ESCAPE})*/
  INVALID  = /#{INVALID1}|#{INVALID2}/
  W        = /[ \t\r\n\f]*/
  D        = /d|\\0{0,4}(44|64)(\r\n|[ \t\r\n\f])?/
  E        = /e|\\0{0,4}(45|65)(\r\n|[ \t\r\n\f])?/
  N        = /n|\\0{0,4}(4e|6e)(\r\n|[ \t\r\n\f])?|\\n/
  O        = /o|\\0{0,4}(4f|6f)(\r\n|[ \t\r\n\f])?|\\o/
  T        = /t|\\0{0,4}(54|74)(\r\n|[ \t\r\n\f])?|\\t/
  V        = /v|\\0{0,4}(58|78)(\r\n|[ \t\r\n\f])?|\\v/
  S        = /[ \t\r\n\f]+/

  require 'strscan'
  require 'forwardable'
  require 'gammo/css_selector/errors'
  require 'gammo/css_selector/ast/selector'
  require 'gammo/css_selector/ast/combinator'

  extend Forwardable
  def_delegators :@scanner, :scan, :eos?

  def initialize(input)
    super()
    @yydebug = true
    @input = input
    @scanner = StringScanner.new(input)
  end

  def parse
    @query = []
    advance { |symbol, val| @query << [symbol, val] }
    do_parse
  end

  def token(symbol, val, &block)
    @prev_token = symbol
    block.call(symbol, val)
  end

  def next_token
    @query.shift
  end

  EXPR_TOKENS = {
    '='  => :T_EQUAL,
    '['  => :T_LBRACK,
    ']'  => :T_RBRACK,
    ')'  => :T_RPAREN,
    '.'  => :T_DOT,
    ','  => :T_COMMA,
    ':'  => :T_COLON
  }.freeze

  # Declaring the regexp consisting of EXPR_TOKENS keys to keep the token order.
  EXPRS = /=|\[|\]|@|,|\.|\)|\:/

  def fetch(key, constraints)
    unless symbol = constraints[key]
      fail ParseError, "unexpected token: #{symbol}, want = #{constraints.keys}"
    end
    yield symbol
  end

  LEXER_TOKENS = []
  Pattern = Struct.new(:pattern, :token, :range)
  def self.map(pattern, token, range: nil)
    LEXER_TOKENS << Pattern.new(pattern, token, range)
  end

  map(S,                 :T_S)
  map(/\~=/,             :T_INCLUDES)
  map(/\|=/,             :T_DASHMATCH)
  map(/\^=/,             :T_PREFIXMATCH)
  map(/\$=/,             :T_SUFFIXMATCH)
  map(/\*=/,             :T_SUBSTRINGMATCH)
  map(/<!--/,            :T_CDO)
  map(/-->/,             :T_CDC)
  map(/#{IDENT}\(/,      :T_FUNCTION)
  map(/#{NUM}%/,         :T_PERCENTAGE)
  map(/#{NUM}#{IDENT}/,  :T_DIMENSION)
  map(IDENT,             :T_IDENT)
  map(STRING,            :T_STRING, range: 1..-2) # Remove quotes
  map(NUM,               :T_NUMBER)
  map(/##{NAME}/,        :T_HASH,   range: 1..-1) # Remove hash ('#')
  map(/#{W}\+/,          :T_PLUS)
  map(/#{W}\-/,          :T_MINUS)
  map(/#{W}>/,           :T_GREATER)
  map(/#{W},/,           :T_COMMA)
  map(/#{W}~/,           :T_TILDE)
  map(/:#{N}#{O}#{T}\(/, :T_NOT)
  map(/@#{IDENT}/,       :T_ATKEYWORD)
  map(/#{INVALID}/,      :T_INVALID)
  map(/\|/,              :T_PIPE)
  map(/\*/,              :T_ASTERISK)

  # TODO: ignore comment token
  def advance(&block)
    @prev_token = nil
    until eos?
      next if LEXER_TOKENS.find do |pattern|
        next false unless matched = scan(pattern.pattern)
        matched = matched[pattern.range] if pattern.range
        token pattern.token, matched, &block
        break true
      end
      if expr = scan(EXPRS)
        fetch(expr, EXPR_TOKENS) { |symbol| token symbol, expr, &block }
        next
      end
      fail ParseError, "unexpected token: '#{@scanner.string[@scanner.pos..-1]}'"
    end
  end
