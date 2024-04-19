module ActiveKit
  module Search
    extend ActiveSupport::Autoload

    autoload :Index
    autoload :Key
    autoload :Search
    autoload :SearchResult
    autoload :Searcher
    autoload :Searching
    autoload :Suggestion
    autoload :SuggestionResult

    mattr_accessor :redis, instance_accessor: false
  end
end
