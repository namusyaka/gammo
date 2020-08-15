module Gammo
  module XPath
    Error            = Class.new(StandardError)
    ParseError       = Class.new(Error)
    NotFoundError    = Class.new(Error)
    UnreachableError = Class.new(Error)
    TypeError        = Class.new(Error)
  end
end
