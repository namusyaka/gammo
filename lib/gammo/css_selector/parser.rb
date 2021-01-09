#
# DO NOT MODIFY!!!!
# This file is automatically generated by Racc 1.5.0
# from Racc grammar file "".
#

require 'racc/parser.rb'
module Gammo
  module CSSSelector
    class Parser < Racc::Parser

module_eval(<<'...end parser.y/module_eval...', 'parser.y', 197)

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
...end parser.y/module_eval...
##### State transition tables begin ###

racc_action_table = [
    84,    85,    86,    87,    88,    89,    90,    52,    55,    39,
    18,    23,    38,    24,    27,    17,    53,    20,    17,    19,
    21,    18,    23,    -5,    24,    96,    57,    22,    20,    17,
    19,    21,    18,    27,    27,    24,    27,    38,    22,    20,
    17,    19,    21,    18,    23,    36,    24,   100,    99,    22,
    20,    17,    19,    21,    37,    23,    23,    24,    24,    27,
    22,    20,    20,    27,    21,    21,    39,    23,    23,    24,
    24,    22,    22,    20,    20,    48,    21,    21,    -8,    23,
    -8,    24,    -2,    22,    22,    20,    49,    50,    21,    70,
    27,    27,    46,    -2,    -2,    22,    84,    85,    86,    87,
    88,    89,    90,    76,    77,    78,    79,    80,    81,    76,
    77,    78,    79,    80,    81,    27,    27,    92,    93,    27,
    25,    27,   101,    27,    27,    46,    45,    47,    27,    27,
    43,    27,    40 ]

racc_action_check = [
    83,    83,    83,    83,    83,    83,    83,    41,    42,    19,
     0,     0,    18,     0,    47,    41,    41,     0,     0,     0,
     0,    65,    65,     2,    65,    83,    42,     0,    65,    65,
    65,    65,    44,    52,    48,    44,     2,    52,    65,    44,
    44,    44,    44,    31,    31,    16,    31,    94,    94,    44,
    31,    31,    31,    31,    16,     8,    33,     8,    33,    49,
    31,     8,    33,    50,     8,    33,    53,    32,     6,    32,
     6,     8,    33,    32,     6,    30,    32,     6,     4,     7,
     4,     7,    29,    32,     6,     7,    30,    30,     7,    54,
    57,     4,    29,    29,    29,     7,    71,    71,    71,    71,
    71,    71,    71,    69,    69,    69,    69,    69,    69,    82,
    82,    82,    82,    82,    82,    58,    70,    72,    74,    75,
     1,    91,    95,    97,    99,    26,    25,    28,   100,    23,
    22,    21,    20 ]

racc_action_pointer = [
     1,   120,    23,   nil,    78,   nil,    58,    69,    45,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,    36,   nil,    -5,    -8,
   123,   118,   104,   116,   nil,   126,   112,   nil,   125,    79,
    72,    34,    57,    46,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,    -2,    -1,   nil,    23,   nil,   nil,     1,    21,    46,
    50,   nil,    20,    49,    80,   nil,   nil,    77,   102,   nil,
   nil,   nil,   nil,   nil,   nil,    12,   nil,   nil,   nil,    83,
   103,    93,    89,   nil,   107,   106,   nil,   nil,   nil,   nil,
   nil,   nil,    89,    -3,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,   108,   nil,   nil,    39,   111,   nil,   110,   nil,   111,
   115,   nil,   nil,   nil,   nil ]

racc_action_default = [
   -69,   -69,    -1,    -6,    -1,   -13,   -15,   -16,   -19,   -20,
   -22,   -23,   -24,   -25,   -26,   -27,   -69,   -29,   -32,   -34,
   -69,    -1,   -49,    -1,   -68,   -69,    -2,    -3,   -69,   -12,
   -69,   -69,   -17,   -18,   -21,   -28,   -32,   -33,   -30,   -31,
   -35,   -69,   -69,   -50,   -69,   105,    -4,    -1,    -1,    -1,
    -1,   -14,    -1,   -69,   -69,   -47,   -48,    -1,    -1,   -62,
   -63,   -64,   -65,   -66,   -67,   -69,    -9,   -10,   -11,   -38,
    -1,   -69,   -69,    -7,   -69,    -1,   -41,   -42,   -43,   -44,
   -45,   -46,   -38,   -69,   -52,   -53,   -54,   -55,   -56,   -57,
   -58,    -1,   -61,   -37,   -69,   -69,   -51,    -1,   -59,    -1,
    -1,   -36,   -60,   -39,   -40 ]

racc_goto_table = [
    28,     3,    30,    34,    74,    60,    91,    32,    33,    61,
    62,    63,    64,    35,    54,    42,    56,    95,    97,    41,
    83,    44,     1,    58,    29,     2,    31,    34,    34,    51,
    59,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,    65,    66,    67,    68,   nil,
    69,   nil,   nil,   nil,   nil,    71,    72,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,    73,   nil,    82,   nil,
   nil,   nil,   nil,    94,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,    98,
   nil,   nil,   nil,   nil,   nil,   102,   nil,   103,   104 ]

racc_goto_check = [
     2,     5,     2,    12,    20,    10,    25,    11,    11,    13,
    14,    15,    16,    18,    19,    22,    23,    20,    25,     2,
    24,     2,     1,    26,     3,     4,     7,    12,    12,     8,
     9,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,     2,     2,     2,     2,   nil,
     2,   nil,   nil,   nil,   nil,     2,     2,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,     5,   nil,     2,   nil,
   nil,   nil,   nil,     2,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,     2,
   nil,   nil,   nil,   nil,   nil,     2,   nil,     2,     2 ]

racc_goto_pointer = [
   nil,    22,    -2,    20,    25,     1,   nil,    22,    -2,   -14,
   -39,     1,    -5,   -35,   -34,   -33,   -32,   nil,    -3,   -27,
   -65,   nil,    -7,   -26,   -51,   -65,   -21 ]

racc_goto_default = [
   nil,   nil,   nil,    26,   nil,   nil,     4,   nil,     5,     6,
     7,     8,     9,    10,    11,    12,    13,    14,    15,    16,
   nil,    75,   nil,   nil,   nil,   nil,   nil ]

racc_reduce_table = [
  0, 0, :racc_error,
  0, 31, :_reduce_none,
  1, 31, :_reduce_none,
  1, 32, :_reduce_none,
  2, 32, :_reduce_none,
  1, 30, :_reduce_5,
  1, 33, :_reduce_6,
  5, 33, :_reduce_7,
  1, 34, :_reduce_none,
  3, 36, :_reduce_9,
  3, 36, :_reduce_10,
  3, 36, :_reduce_11,
  1, 36, :_reduce_12,
  1, 35, :_reduce_13,
  3, 35, :_reduce_14,
  1, 37, :_reduce_none,
  1, 37, :_reduce_none,
  2, 37, :_reduce_17,
  2, 37, :_reduce_18,
  1, 37, :_reduce_19,
  1, 40, :_reduce_20,
  2, 40, :_reduce_21,
  1, 41, :_reduce_none,
  1, 41, :_reduce_none,
  1, 41, :_reduce_none,
  1, 41, :_reduce_none,
  1, 41, :_reduce_none,
  1, 38, :_reduce_27,
  2, 38, :_reduce_28,
  1, 48, :_reduce_29,
  2, 48, :_reduce_30,
  2, 48, :_reduce_31,
  1, 47, :_reduce_32,
  2, 39, :_reduce_33,
  1, 39, :_reduce_34,
  2, 43, :_reduce_35,
  7, 44, :_reduce_36,
  6, 44, :_reduce_37,
  0, 49, :_reduce_none,
  4, 49, :_reduce_39,
  4, 49, :_reduce_40,
  1, 50, :_reduce_41,
  1, 50, :_reduce_42,
  1, 50, :_reduce_43,
  1, 50, :_reduce_44,
  1, 50, :_reduce_45,
  1, 50, :_reduce_46,
  3, 45, :_reduce_47,
  3, 45, :_reduce_48,
  0, 51, :_reduce_none,
  1, 51, :_reduce_none,
  4, 52, :_reduce_51,
  1, 54, :_reduce_none,
  1, 54, :_reduce_none,
  1, 54, :_reduce_none,
  1, 54, :_reduce_none,
  1, 54, :_reduce_none,
  1, 54, :_reduce_none,
  1, 54, :_reduce_58,
  2, 53, :_reduce_59,
  3, 53, :_reduce_60,
  5, 46, :_reduce_61,
  1, 55, :_reduce_none,
  1, 55, :_reduce_none,
  1, 55, :_reduce_none,
  1, 55, :_reduce_none,
  1, 55, :_reduce_none,
  1, 55, :_reduce_none,
  1, 42, :_reduce_68 ]

racc_reduce_n = 69

racc_shift_n = 105

racc_token_table = {
  false => 0,
  :error => 1,
  :T_COMMA => 2,
  :T_PLUS => 3,
  :T_MINUS => 4,
  :T_HYPHEN => 5,
  :T_DIMENSION => 6,
  :T_NUMBER => 7,
  :T_STRING => 8,
  :T_IDENT => 9,
  :T_NOT => 10,
  :T_RBRACK => 11,
  :T_HASH => 12,
  :T_S => 13,
  :T_GREATER => 14,
  :T_TILDE => 15,
  :T_DOT => 16,
  :T_PIPE => 17,
  :T_ASTERISK => 18,
  :T_LBRACK => 19,
  :T_PREFIXMATCH => 20,
  :T_SUFFIXMATCH => 21,
  :T_SUBSTRINGMATCH => 22,
  :T_EQUAL => 23,
  :T_INCLUDES => 24,
  :T_DASHMATCH => 25,
  :T_COLON => 26,
  :T_FUNCTION => 27,
  :T_RPAREN => 28 }

racc_nt_base = 29

racc_use_result_var = true

Racc_arg = [
  racc_action_table,
  racc_action_check,
  racc_action_default,
  racc_action_pointer,
  racc_goto_table,
  racc_goto_check,
  racc_goto_default,
  racc_goto_pointer,
  racc_nt_base,
  racc_reduce_table,
  racc_token_table,
  racc_shift_n,
  racc_reduce_n,
  racc_use_result_var ]

Racc_token_to_s_table = [
  "$end",
  "error",
  "T_COMMA",
  "T_PLUS",
  "T_MINUS",
  "T_HYPHEN",
  "T_DIMENSION",
  "T_NUMBER",
  "T_STRING",
  "T_IDENT",
  "T_NOT",
  "T_RBRACK",
  "T_HASH",
  "T_S",
  "T_GREATER",
  "T_TILDE",
  "T_DOT",
  "T_PIPE",
  "T_ASTERISK",
  "T_LBRACK",
  "T_PREFIXMATCH",
  "T_SUFFIXMATCH",
  "T_SUBSTRINGMATCH",
  "T_EQUAL",
  "T_INCLUDES",
  "T_DASHMATCH",
  "T_COLON",
  "T_FUNCTION",
  "T_RPAREN",
  "$start",
  "selectors_group",
  "optional_whitespaces",
  "repeatable_whitespaces",
  "repeatable_selectors",
  "selector",
  "repeatable_simple_selector_sequence",
  "combinator",
  "simple_selector_sequence",
  "type_selector",
  "universal",
  "repeatable_selector_operators",
  "selector_operators",
  "hash",
  "class",
  "attrib",
  "pseudo",
  "negation",
  "element_name",
  "namespace_prefix",
  "optional_attrib_clause",
  "attrib_operators",
  "optional_colon",
  "functional_pseudo",
  "repeatable_expressions",
  "expression",
  "negation_arg" ]

Racc_debug_parser = false

##### State transition tables end #####

# reduce 0 omitted

# reduce 1 omitted

# reduce 2 omitted

# reduce 3 omitted

# reduce 4 omitted

module_eval(<<'.,.,', 'parser.y', 43)
  def _reduce_5(val, _values, result)
     result = val[0]
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 47)
  def _reduce_6(val, _values, result)
          result = AST::SelectorsGroup.new
      result << val[0]

    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 51)
  def _reduce_7(val, _values, result)
          result = val[0]
      result << val[4]

    result
  end
.,.,

# reduce 8 omitted

module_eval(<<'.,.,', 'parser.y', 62)
  def _reduce_9(val, _values, result)
     result = :next_sibling
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 63)
  def _reduce_10(val, _values, result)
     result = :child
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 64)
  def _reduce_11(val, _values, result)
     result = :subsequent_sibling
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 65)
  def _reduce_12(val, _values, result)
     result = :descendant
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 69)
  def _reduce_13(val, _values, result)
          result = val[0]

    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 72)
  def _reduce_14(val, _values, result)
          result = val[0]
      result.combine(AST::Combinator.fetch(val[1]).new(val[2]))

    result
  end
.,.,

# reduce 15 omitted

# reduce 16 omitted

module_eval(<<'.,.,', 'parser.y', 84)
  def _reduce_17(val, _values, result)
          val[0].selectors.concat(val[1])
      result = val[0]

    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 88)
  def _reduce_18(val, _values, result)
          val[0].selectors.concat(val[1])
      result = val[0]

    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 92)
  def _reduce_19(val, _values, result)
          any = AST::Selector::Universal.new
      any.selectors.concat(val[0])
      result = any

    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 98)
  def _reduce_20(val, _values, result)
     result = [val[0]]
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 99)
  def _reduce_21(val, _values, result)
     result = val[0] << val[1]
    result
  end
.,.,

# reduce 22 omitted

# reduce 23 omitted

# reduce 24 omitted

# reduce 25 omitted

# reduce 26 omitted

module_eval(<<'.,.,', 'parser.y', 110)
  def _reduce_27(val, _values, result)
     result = AST::Selector::Type.new(element_name: val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 111)
  def _reduce_28(val, _values, result)
     result = AST::Selector::Type.new(element_name: val[1], namespace_prefix: val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 115)
  def _reduce_29(val, _values, result)
     result = val[0]
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 116)
  def _reduce_30(val, _values, result)
     result = val[0]
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 117)
  def _reduce_31(val, _values, result)
     result = val[1]
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 120)
  def _reduce_32(val, _values, result)
     result = val[0]
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 124)
  def _reduce_33(val, _values, result)
     result = AST::Selector::Universal.new(namespace_prefix: val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 125)
  def _reduce_34(val, _values, result)
     result = AST::Selector::Universal.new
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 128)
  def _reduce_35(val, _values, result)
     result = AST::Selector::Class.new(val[1])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 140)
  def _reduce_36(val, _values, result)
          op, value = val[4]
      result = AST::Selector::Attrib.fetch(op).new(key: val[2], value: value, namespace_prefix: val[2])

    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 144)
  def _reduce_37(val, _values, result)
          op, value = val[4]
      result = AST::Selector::Attrib.fetch(op).new(key: val[2], value: value)

    result
  end
.,.,

# reduce 38 omitted

module_eval(<<'.,.,', 'parser.y', 149)
  def _reduce_39(val, _values, result)
     result = [val[0], val[2]]
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 150)
  def _reduce_40(val, _values, result)
     result = [val[0], val[2]]
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 153)
  def _reduce_41(val, _values, result)
     result = :prefix_match
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 154)
  def _reduce_42(val, _values, result)
     result = :suffix_match
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 155)
  def _reduce_43(val, _values, result)
     result = :substring_match
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 156)
  def _reduce_44(val, _values, result)
     result = :equal
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 157)
  def _reduce_45(val, _values, result)
     result = :includes
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 158)
  def _reduce_46(val, _values, result)
     result = :dash_match
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 162)
  def _reduce_47(val, _values, result)
     result = AST::Selector::Pseudo.fetch(val[2]).new
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 163)
  def _reduce_48(val, _values, result)
     result = val[2]
    result
  end
.,.,

# reduce 49 omitted

# reduce 50 omitted

module_eval(<<'.,.,', 'parser.y', 169)
  def _reduce_51(val, _values, result)
     result = AST::Selector::Pseudo.fetch(val[0].slice(0..-2)).new(val[2])
    result
  end
.,.,

# reduce 52 omitted

# reduce 53 omitted

# reduce 54 omitted

# reduce 55 omitted

# reduce 56 omitted

# reduce 57 omitted

module_eval(<<'.,.,', 'parser.y', 173)
  def _reduce_58(val, _values, result)
     result = val[0]
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 176)
  def _reduce_59(val, _values, result)
     result = [val[0]]
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 178)
  def _reduce_60(val, _values, result)
          val[0] << val[1]
      result = val[0]

    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 184)
  def _reduce_61(val, _values, result)
     result = AST::Selector::Negation.new(val[2])
    result
  end
.,.,

# reduce 62 omitted

# reduce 63 omitted

# reduce 64 omitted

# reduce 65 omitted

# reduce 66 omitted

# reduce 67 omitted

module_eval(<<'.,.,', 'parser.y', 191)
  def _reduce_68(val, _values, result)
     result = AST::Selector::ID.new(val[0])
    result
  end
.,.,

def _reduce_none(val, _values, result)
  val[0]
end

    end   # class Parser
  end   # module CSSSelector
end   # module Gammo