require 'delegate'

module Gammo
  class Parser
    # @!visibility private
    InsertionModeStack = Class.new(DelegateClass(Array))
  end
end
