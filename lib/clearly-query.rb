require 'active_support/all'

require 'clearly-query/version'
require 'clearly-query/errors'

module ClearlyQuery
  autoload :Helper, 'clearly-query/helper'
  autoload :Validate, 'clearly-query/validate'

  module Compose
    autoload :Core, 'clearly-query/compose/core'
    autoload :Subset, 'clearly-query/compose/subset'
    autoload :Comparison, 'clearly-query/compose/comparison'
    autoload :Range, 'clearly-query/compose/range'
  end

  autoload :Parser, 'clearly-query/parser'
  autoload :Composer, 'clearly-query/composer'
  autoload :Definition, 'clearly-query/definition'

end