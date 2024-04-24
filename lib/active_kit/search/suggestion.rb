module ActiveKit
  module Search
    class Suggestion
      def initialize(current_class:, describer:)
        @redis = ActiveKit::Search.redis
        @current_class = current_class
        @describer = describer
        @current_class_name = current_class.to_s.parameterize.pluralize
      end

      def add(term:, score: 1, increment: true)
        command = ["FT.SUGADD", key, term, score, (increment ? 'INCR' : '')]
        @redis.call(command)
      end

      def fetch(prefix:)
        command = ["FT.SUGGET", key, prefix, "FUZZY", "MAX", "10", "WITHSCORES"]
        results = @redis.call(command)

        SuggestionResult.new(prefix: prefix, results: results)
      end

      def del(term:)
        command = ["FT.SUGDEL", key, term]
        @redis.call(command)
      end

      def len
        command = ["FT.SUGLEN", key]
        @redis.call(command)
      end

      private

      def key
        "activekit:search:suggestions:#{@current_class_name}:#{@describer.database.call}"
      end
    end
  end
end
