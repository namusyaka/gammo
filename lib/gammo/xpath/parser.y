class Gammo::XPath::Parser

token T_SLASH
      T_SLASHSLASH
      T_PIPE
      T_PLUS
      T_MINUS
      T_EQ
      T_NEQ
      T_LT
      T_GT
      T_LTE
      T_GTE
      T_AND
      T_OR
      T_DIV
      T_MOD
      T_MUL
      T_LPAREN
      T_RPAREN
      T_LBRACK
      T_RBRACK
      T_DOT
      T_DOTDOT
      T_AT
      T_COMMA
      T_COLONCOLON
      T_NC_NAME
      T_Q_NAME
      T_FUNCTION_NAME
      T_NAME_TEST
      T_NODE_TYPE
      T_AXIS_NAME
      T_VARIABLE_REFERENCE
      T_LITERAL
      T_NUMBER

start expr

rule
  location_path:
    relative_location_path {
      result = val[0]
      result.absolute = false
    }
    | absolute_location_path {
      result = val[0]
      result.absolute = true
    }

  absolute_location_path:
    T_SLASH { result = AST::LocationPath.new }
    | T_SLASH relative_location_path { result = val[1] }
    | descendant_or_self relative_location_path {
      result = val[1]
      result.insert_first_step(val[0])
    }

  relative_location_path:
    step {
      result = AST::LocationPath.new
      result.append_step(val[0])
    }
    | relative_location_path T_SLASH step {
      result = val[0]
      result.append_step(val[2])
    }
    | relative_location_path T_SLASHSLASH step {
      result = val[0]
      result.append_step(val[1])
      result.append_step(val[2])
    }

  step:
    node_test optional_predicates {
      result = AST::Axis::Child.new(node_test: val[0], predicates: val[1])
    }
    | axis_specifier node_test optional_predicates {
      axis_base_class = val[0]
      axis_base_class = AST::Axis.fetch(axis_base_class.gsub(/-/, '_')) if axis_base_class.instance_of?(String)
      result = axis_base_class.new(node_test: val[1], predicates: val[2])
    }
    | abbreviated_step

  axis_specifier:
    T_AXIS_NAME T_COLONCOLON | T_AT { result = AST::Axis::Attribute }

  node_test:
    T_NAME_TEST {
      local, namespace = expand_qname(val[0])
      result = AST::NodeTest::Name.new(local: local, namespace: namespace)
    }
    | T_NODE_TYPE T_LPAREN T_RPAREN {
      result = AST::NodeTest.fetch(val[0]).new
    }

  descendant_or_self:
    T_SLASHSLASH {
      result = AST::Axis::DescendantOrSelf.new(node_test: AST::NodeTest::Any.new)
    }

  # Since there is no way that defining repeated expressions,
  # need to define an original rule for handling that case recursively.
  # TODO(kunpei): need test
  repeatable_predicates:
    predicate { result = [AST::Predicate.new(val[0])] }
    | repeatable_predicates predicate {
      result = val[0]
      result << val[1]
    }

  optional_predicates:
    | repeatable_predicates { result = val[0] }

  predicate: T_LBRACK predicate_expr T_RBRACK { result = val[1] }
  predicate_expr: expr

  abbreviated_step:
    T_DOT      { result = AST::Axis::Self.new(node_test: AST::NodeTest::Any.new) }
    | T_DOTDOT { result = AST::Axis::Parent.new(node_test: AST::NodeTest::Any.new) }

  expr: or_expr

  primary_expr:
    T_VARIABLE_REFERENCE     { result = AST::Value::VariableReference.new(val[0]) }
    | T_LPAREN expr T_RPAREN { result = val[1] }
    | T_LITERAL              { result = AST::Value::String.new(val[0].to_s) }
    | T_NUMBER               { result = AST::Value::Number.new(val[0].include?(?.) ? val[0].to_f : val[0].to_i) }
    | function_call

  function_call:
    T_FUNCTION_NAME T_LPAREN arguments T_RPAREN {
      result = AST::Function.fetch(val[0]).new(*val[2])
    }
    | T_FUNCTION_NAME T_LPAREN T_RPAREN {
      result = AST::Function.fetch(val[0]).new
    }

  argument: expr
  
  # Since there is no way that defining repeated expressions,
  # need to define an original rule for handling that case recursively.
  # TODO(kunpei): need test
  arguments: 
    argument {
      result = []
      result << val[0]
    }
    | arguments T_COMMA argument {
      result = val[0]
      result << val[2]
    }

  union_expr:
    path_expr
    | union_expr T_PIPE path_expr {
      result = AST::UnionExpr.new(val[0], val[2])
    }

  path_expr:
    location_path
    | filter_expr
    | filter_expr T_SLASH relative_location_path {
      val[2].absolute = true
      result = AST::Path.new(val[0], val[2])
    }
    | filter_expr descendant_or_self relative_location_path {
      val[2].insert_first_step(val[1])
      val[2].absolute = true
      result = AST::Path.new(val[0], val[2])
    }

  filter_expr:
    primary_expr
    | primary_expr repeatable_predicates {
      result = AST::Filter.new(val[0], predicates: val[1])
    }

  or_expr:
    and_expr
    | or_expr T_OR and_expr { result = AST::OrExpr.new(a: val[0], b: val[2]) }

  and_expr:
    equality_expr
    | and_expr T_AND equality_expr { result = AST::AndExpr.new(a: val[0], b: val[2]) }

  equality_expr:
    relational_expr
    | equality_expr T_EQ relational_expr { result = AST::EqExpr.new(val[0], val[2]) }
    | equality_expr T_NEQ relational_expr { result =  AST::NeqExpr.new(val[0], val[2]) }
    
  relational_expr:
    additive_expr
    | relational_expr T_LT additive_expr  { result = AST::LtExpr.new(val[0], val[2]) }
    | relational_expr T_GT additive_expr  { result = AST::GtExpr.new(val[0], val[2]) }
    | relational_expr T_LTE additive_expr { result = AST::LteExpr.new(val[0], val[2]) }
    | relational_expr T_GTE additive_expr { result = AST::GteExpr.new(val[0], val[2]) }

  additive_expr:
    multiplicative_expr
    | additive_expr T_PLUS multiplicative_expr {
      result = AST::PlusExpr.new(val[0], val[2])
    }
    | additive_expr T_MINUS multiplicative_expr {
      result = AST::MinusExpr.new(val[0], val[2])
    }

  multiplicative_expr:
    unary_expr
    | multiplicative_expr T_MUL unary_expr {
      result = AST::MultiplyExpr.new(val[0], val[2])
    }
    | multiplicative_expr T_DIV unary_expr {
      result = AST::DividedExpr.new(val[0], val[2])
    }
    | multiplicative_expr T_MOD unary_expr {
      result = AST::ModuloExpr.new(val[0], val[2])
    }

  unary_expr:
    union_expr
    | T_MINUS unary_expr {
      result = AST::Negative.new(val[1])
    }
end

---- inner

  # 2.2 Characters (Extensible Markup Language (XML) 1.0 (Fifth Edition))
  #
  # This represents "Char" range defined in 2.2 Characters.
  # [2] Char ::=
  #   [#x1-#xD7FF] |
  #   [#xE000-#xFFFD] |
  #   [#x10000-#x10FFFF] /* any Unicode character, excluding the surrogate blocks, FFFE, and FFFF. */
  #
  # @see https://www.w3.org/TR/xml11/#charsets
  CHAR = /[\x9\xA\xD\u{20}-\u{d7ff}\u{e000}-\u{fffd}\u{10000}-\u{10ffff}]/

  # 2.3 Common Syntactic Constructs (Extensible Markup Language (XML) 1.0 (Fifth Edition))
  #
  # [3] S ::= (#x20 | #x9 | #xD | #A)+
  #
  # @see https://www.w3.org/TR/xml11/#NT-S
  S = /[\x20\x9\xD\xA]/

  # [4] NameStartChar ::=
  #   ":" |
  #   [A-Z] |
  #   "_" |
  #   [a-z] |
  #   [#xC0-#xD6] |
  #   [#xD8-#xF6] |
  #   [#xF8-#x2FF] |
  #   [#x370-#x37D] |
  #   [#x37F-#x1FFF] |
  #   [#x200C-#x200D] |
  #   [#x2070-#x218F] |
  #   [#x2C00-#x2FEF] |
  #   [#x3001-#xD7FF] |
  #   [#xF900-#xFDCF] |
  #   [#xFDF0-#xFFFD] |
  #   [#x10000-#xEFFFF]
  #
  # @see https://www.w3.org/TR/xml11/#NT-NameStartChar
  name_start_chars = %w[
    :
    a-zA-Z_
    \\u00c0-\\u00d6
    \\u00d8-\\u00f6
    \\u00f8-\\u02ff
    \\u0370-\\u037d
    \\u037f-\\u1fff
    \\u200c-\\u200d
    \\u2070-\\u218f
    \\u2c00-\\u2fef
    \\u3001-\\ud7ff
    \\uf900-\\ufdcf
    \\ufdf0-\\ufffd
    \\u{10000}-\\u{effff}
  ]
  NAME_START_CHARS = /[#{name_start_chars.join}]/

  # [4a] NameChar ::=
  #   NameStartChar |
  #   "-" |
  #   "." |
  #   [0-9] |
  #   #xB7 |
  #   [#x0300-#x036F] |
  #   [#x203F-#x2040]
  #
  # @see https://www.w3.org/TR/xml11/#NT-NameChar
  name_chars = name_start_chars + %w[
    \\-
    \\.
    0-9
    \\u00b7
    \\u0300-\\u036f
    \\u203f-\\u2040
  ]
  NAME_CHARS = /[#{name_chars.join}]/

  # [5] Name ::= NameStartChar (NameChar)*
  #
  # @see https://www.w3.org/TR/1999/REC-xpath-19991116/#NT-Name
  NAME = /#{NAME_START_CHARS}#{NAME_CHARS}*/

  # 2.3. Axes
  #
  # [6] AxisName ::=
  #   'ancestor'
  #   | 'ancestor-or-self'
  #   | 'attribute'
  #   | 'child'
  #   | 'descendant'
  #   | 'descendant-or-self'
  #   | 'following'
  #   | 'following-sibling'
  #   | 'namespace'
  #   | 'parent'
  #   | 'preceding'
  #   | 'preceding-sibling'
  #   | 'self'
  #
  # @see https://www.w3.org/TR/1999/REC-xpath-19991116/#NT-AxisName
  AXES = /
    ancestor-or-self|
    ancestor|
    attribute|
    child|
    descendant-or-self|
    descendant|
    following-sibling|
    following|
    namespace|
    parent|
    preceding-sibling|
    preceding|
    self
  /x

  # 3 Declaring Namespaces
  #
  # The "NCName" is picked from the section.
  #
  # Note that we need to take care of exceptional handling.
  #
  # [4] NCName ::= NCNameStartChar NCNameChar* /* An XML Name, minus the ":" */
  # [5] NCNamrChar ::= NameChar - ':'
  # [6] NCNameStartChar ::= NameStartChar - ':'
  #
  # @see https://www.w3.org/TR/xml-names11/#ns-decl
  NC_NAME_CHARS       = /[#{(name_chars - [':']).join}]/
  NC_NAME_START_CHARS = /[#{(name_start_chars - [':']).join}]/
  NC_NAME             = /#{NC_NAME_START_CHARS}#{NC_NAME_CHARS}*/

  # 4. Qualified Names
  #
  # The rules for "QName", "PrefixedName", "UnprefixedName", "Prefix" and
  # "LocalPart" are picked from the section.
  #
  # [7] QName ::= PrefixedName | UnprefixedName
  # [8] PrefixedName ::= Prefix ':' LocalPart
  # [9] UnprefixedName ::= LocalPart
  # [10] Prefix ::= NCName
  # [11] LocalPart ::= NCName
  #
  # @see https://www.w3.org/TR/xml-names11/#ns-qualnames
  PREFIX          = NC_NAME
  LOCAL_PART      = NC_NAME
  PREFIXED_NAME   = /#{PREFIX}:#{LOCAL_PART}/
  UNPREFIXED_NAME = LOCAL_PART
  Q_NAME          = /#{PREFIXED_NAME}|#{UNPREFIXED_NAME}/

  # 3.7 Lexical Structure
  #
  # The rules for "NodeType" and "Digits" are picked from the section.
  # @see https://www.w3.org/TR/1999/REC-xpath-19991116/#exprlex
  DIGITS = /[0-9]+/
  NODE_TYPE = /comment|text|processing-instruction|node/

  # EXPR_TOKENS is defined for tokenizing primitive tokens for "ExprToken",
  # except other rules.
  # @see https://www.w3.org/TR/1999/REC-xpath-19991116/#NT-ExprToken
  EXPR_TOKENS = {
    '(' => :T_LPAREN,
    ')' => :T_RPAREN,
    '[' => :T_LBRACK,
    ']' => :T_RBRACK,
    '.' => :T_DOT,
    '..' => :T_DOTDOT,
    '@' => :T_AT,
    ',' => :T_COMMA,
    '::' => :T_COLONCOLON
  }.freeze
  # Declaring the regexp consisting of EXPR_TOKENS keys to keep the token order.
  EXPRS = /\(|\)|\[|\]|@|,|::|\.\.|\./

  # OPERATOR_TOKENS is defined for tokenizing primitive tokens for "Operator"
  # and "OperatorName" except other rules.
  # @see https://www.w3.org/TR/1999/REC-xpath-19991116/#NT-Operator
  OPERATOR_TOKENS = {
    'and' => :T_AND,
    'or'  => :T_OR,
    'mod' => :T_MOD,
    'div' => :T_DIV,
    '/'   => :T_SLASH,
    '//'  => :T_SLASHSLASH,
    "|"   => :T_PIPE,
    '+'   => :T_PLUS,
    '-'   => :T_MINUS,
    '='   => :T_EQ,
    '!='  => :T_NEQ,
    '<'   => :T_LT,
    '>'   => :T_GT,
    '<='  => :T_LTE,
    '>='  => :T_GTE
  }.freeze
  # Declaring the regexp consisting of OPERATOR_TOKENS keys to keep the token order.
  OPERATORS = /and|or|mod|div|\/\/|\/|\||\+|-|\=|!=|<=|>=|<|>/

  require 'strscan'
  require 'forwardable'
  require 'gammo/xpath/errors'
  require 'gammo/xpath/ast/axis'
  require 'gammo/xpath/ast/expression'
  require 'gammo/xpath/ast/function'
  require 'gammo/xpath/ast/node_test'
  require 'gammo/xpath/ast/path'
  require 'gammo/xpath/ast/value'

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

  def next_token
    @query.shift
  end

  def lookup_namespace_uri(prefix)
    prefix == 'xml' ? 'http://www.w3.org/XML/1998/namespace' : nil
  end

  def expand_qname(qname)
    return [qname, nil] unless colon = qname.index(':')
    namespace_uri = lookup_namespace_uri(qname.slice(0..colon))
    fail ParseError, 'invalid qname: %s' % qname unless namespace_uri
    [qname.slice(colon..-1), namespace_uri]
  end

  def token(symbol, val, &block)
    @prev_token = symbol
    block.call(symbol, val)
  end

  def fetch(key, constraints)
    unless symbol = constraints[key]
      fail ParseError, "unexpected token: #{symbol}, want = #{constraints.keys}"
    end
    yield symbol
  end

  def advance(&block)
    @prev_token = nil
    until eos?
      case
      # Skip whitespace everywhere.
      when scan(/#{S}+/) then next
      when expr = scan(EXPRS)
        fetch(expr, EXPR_TOKENS) do |symbol|
          token(symbol, expr, &block)
        end
      when operator = scan(OPERATORS)
        fetch operator, OPERATOR_TOKENS do |symbol|
          # "div" is available in both operator and name_test tokens.
          if symbol == :T_DIV && @prev_token != :T_NUMBER
            token(:T_NAME_TEST, operator, &block)
            next
          end
          token(symbol, operator, &block)
        end
      when axis = scan(AXES) then token(:T_AXIS_NAME, axis, &block)
      when node_type = scan(NODE_TYPE)
        # NOTE: processing-instruction is not supported by Gammo.
        token(:T_NODE_TYPE, node_type, &block)
      when name = scan(/\*|#{NC_NAME}|#{Q_NAME}/)
        if name == ?* && @prev_token == :T_NUMBER
          token(:T_MUL, name, &block)
          next
        end
        # TODO: Stripping should be taken care by regexp.
        token @scanner.peek(1) == ?( ? :T_FUNCTION_NAME : :T_NAME_TEST, name.strip, &block
      when literal = scan(/"[^"]*"|'[^']*'/) then token(:T_LITERAL, literal, &block)
      when number = scan(/#{DIGITS}(\.(#{DIGITS})?)?/) then token(:T_NUMBER, number, &block)
      when ref = scan(/\$#{Q_NAME}/) then token(:T_VARIABLE_REFERENCE, ref, &block)
      else
        fail ParseError, "unexpected token: #{@scanner.string[@scanner.pos..-1]}"
      end
    end
  end
