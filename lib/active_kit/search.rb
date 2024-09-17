module ActiveKit
  module Search
    extend ActiveSupport::Autoload

    autoload :Index
    autoload :Key
    autoload :Manager
    autoload :SearchResult
    autoload :Searcher
    autoload :Searching
    autoload :Suggestion
    autoload :SuggestionResult

    mattr_accessor :redis, instance_accessor: false
  end
end
