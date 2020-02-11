require 'gammo/tags/table'

module Gammo
  module Tags
    def self.lookup(name)
      TABLE[name]
    end
  end
end
