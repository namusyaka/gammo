require 'gammo/xpath/ast/value'

module Gammo
  module XPath
    module AST
      # Class for representing a binary expression.
      # @!visibility private
      class BinaryExpr
        # Constructs a binary expression by given "a" and "b".
        # @param [Gammo::AST::Value, Gammo::AST:NodeSet] a
        # @param [Gammo::AST::Value, Gammo::AST:NodeSet] b
        # @!visibility private
        def initialize(a, b)
          @a = a
          @b = b
        end

        # @!visibility private
        def evaluate(context)
          raise NotImplementedError, "BinaryExpr#evaluate must be implemented"
        end

        private

        # @return [Array<Gammo::AST::Value...>]
        # @!visibility private
        def evaluate_values(context)
          [@a.evaluate(context), @b.evaluate(context.dup)]
        end
      end

      # Class for representing a binary expression that returns a boolean.
      # @!visibility private
      class BoolExpr < BinaryExpr
        # @!visibility private
        def evaluate(context)
          compare(context, *evaluate_values(context))
        end

        private

        # Compares both values and returns a boolean.
        # @param [Context] context
        # @param [Value] left
        # @param [Value] right
        # @return [TrueClass, FalseClass]
        # @!visibility private
        def compare(context, left, right)
          return compare_with_node_set(
            context, left.to_node_set(context), right) if left.node_set?
          return compare_with_node_set(
            context, right.to_node_set(context), left, reverse: true) if right.node_set?
          do_compare(left, right)
        end

        # @!visibility private
        def compare_with_node_set(context, node_set, value, reverse: false)
          if value.node_set?
            node_set.each do |lnode|
              ls = string_from_node(lnode)
              value.to_node_set(context).each do |rnode|
                return true if compare(context, ls, string_from_node(rnode))
              end
            end
          end
          if value.number?
            node_set.each do |node|
              n = number_from_node(node)
              return true if compare(context, *(reverse ? [value, n] : [n, value]))
            end
            return false
          end
          if value.string?
            node_set.each do |node|
              s = string_from_node(node)
              return true if compare(context, *(reverse ? [value, s] : [s, value]))
            end
            return false
          end
          if value.bool?
            b = node_set.to_bool
            return compare(context, *(reverse ? [value, b] : [b, value]))
          end
          fail UnreachableError, 'unreachable pattern happens; please file an issue on github.'
        end

        # @!visibility private
        def string_from_node(node)
          case node
          when Gammo::Node::Element, Gammo::Node::Document
            AST::Value::String.new(node.inner_text)
          when Gammo::Attribute
            AST::Value::String.new(node.value)
          when Gammo::Node::Comment, Gammo::Node::Text
            AST::Value::String.new(node.data)
          end
        end

        # @!visibility private
        def number_from_node(node)
          case node
          when Gammo::Attribute
            # TODO: Consider float case.
            AST::Value::Number.new(node.value.to_i)
          when Gammo::Node::Comment, Gammo::Node::Text
            AST::Value::Number.new(node.data)
          end
        end

        # @!visibility private
        def equal?(left, right)
          return left.to_bool == right.to_bool if left.bool? || right.bool?
          return left.to_number == right.to_number if left.number? || right.number?
          left.to_s == right.to_s
        end
      end

      # @!visibility private
      class EqExpr < BoolExpr
        def do_compare(left, right)
          equal?(left, right)
        end
      end

      # @!visibility private
      class NeqExpr < BoolExpr
        def do_compare(left, right)
          !equal?(left, right)
        end
      end

      # @!visibility private
      class LtExpr < BoolExpr
        def do_compare(left, right)
          left.to_number < right.to_number
        end
      end

      # @!visibility private
      class GtExpr < BoolExpr
        def do_compare(left, right)
          left.to_number > right.to_number
        end
      end

      # @!visibility private
      class LteExpr < BoolExpr
        def do_compare(left, right)
          left.to_number <= right.to_number
        end
      end

      # @!visibility private
      class GteExpr < BoolExpr
        def do_compare(left, right)
          left.to_number >= right.to_number
        end
      end

      # Class for representing Arithmetic operators.
      # @!visibility private
      class ArithmeticExpr < BinaryExpr
        def initialize(a, b)
          super(a, b)
        end

        def evaluate(context)
          # Expects left/right to be Integer.
          Value::Number.new(do_arithmetic(*evaluate_values(context).map(&:to_number)))
        end
      end

      # @!visibility private
      class PlusExpr < ArithmeticExpr
        def do_arithmetic(left, right)
          left + right
        end
      end

      # @!visibility private
      class MinusExpr < ArithmeticExpr
        def do_arithmetic(left, right)
          left - right
        end
      end

      # @!visibility private
      class MultiplyExpr < ArithmeticExpr
        def do_arithmetic(left, right)
          left * right
        end
      end

      # @!visibility private
      class DividedExpr < ArithmeticExpr
        def do_arithmetic(left, right)
          left / right
        end
      end

      # @!visibility private
      class ModuloExpr < ArithmeticExpr
        def do_arithmetic(left, right)
          left % right
        end
      end

      # @!visibility private
      class UnionExpr < BinaryExpr
        def evaluate(context)
          cloned = context.clone
          left, right = @a.evaluate(context), @b.evaluate(cloned)
          left_node_set = left.to_node_set(context)
          right_node_set = right.to_node_set(cloned)

          duplicates = Set.new(left_node_set.nodes)
          right_node_set.each { |node| left_node_set << node if duplicates.add?(node) }
          left
        end
      end

      # @!visibility private
      class Negative
        def initialize(expression)
          @expression = expression
        end

        def evaluate(context)
          AST::Value::Number.new(-@expression.evaluate(context).to_number)
        end
      end

      # Class for representing predicate like "[foo='bar']" and "[0]".
      # @!visibility private
      class Predicate
        def initialize(value)
          @value = value
        end

        def evaluate(context)
          ret = @value.evaluate(context)
          if ret.instance_of?(AST::Value::Number)
            return EqExpr.new(AST::Function::Position.new, ret).evaluate(context)
          end
          ret
        end
      end
    end
  end
end
