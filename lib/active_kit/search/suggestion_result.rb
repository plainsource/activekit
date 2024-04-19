module ActiveKit
  module Search
    class SuggestionResult
      attr_reader :prefix, :documents, :keys, :scores

      def initialize(prefix:, results:)
        @prefix = prefix

        if results
          @documents = results.each_slice(2).map { |key, value| [key, value] }.to_h
          @keys = @documents.keys
          @scores = @documents.values
        else
          @documents = {}
          @keys = []
          @scores = []
        end
      end
    end
  end
end
