module ActiveKit
  module Search
    extend ActiveSupport::Autoload

    autoload :Searcher
    autoload :Searching

    mattr_accessor :redis, instance_accessor: false
  end
end
