require 'active_support/all'

require 'clearly-query/version'

module ClearlyQuery

  module Compose
    autoload :Core, 'clearly-query/compose/core'
    autoload :Subset, 'clearly-query/compose/subset'
    autoload :Comparison, 'clearly-query/compose/comparison'
  end

end