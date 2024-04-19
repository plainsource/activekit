module ActiveKit
  module Search
    class Search
      attr_reader :current_page, :previous_page, :next_page

      def initialize(current_class:)
        @current_class = current_class

        @index = Index.new(current_class: @current_class)
        @key = Key.new(index: @index)
        @suggestion = Suggestion.new(current_class: @current_class)
      end

      def reload(record: nil)
        record ? @key.reload(record: record) : @current_class.all.each { |rec| @key.reload(record: rec) }
        @index.reload
      end

      def clear(record: nil)
        record ? @key.clear(record: record) : @current_class.all.each { |rec| @key.clear(record: rec) }
        @index.reload
      end

      def fetch(**options)
        search_result = @index.fetch(**options)

        if search_result.keys.any?
          @suggestion.add(term: search_result.term)
        else
          @suggestion.del(term: search_result.term)
        end

        @current_page = search_result.current_page
        @previous_page = search_result.previous_page
        @next_page = search_result.next_page

        search_result
      end

      def suggestions(prefix:)
        @suggestion.fetch(prefix: prefix)
      end

      def drop
        total_count = @index.fetch(offset: 0, limit: 0).count
        keys = @index.fetch(offset: 0, limit: total_count).keys
        @key.drop(keys: keys)
        @index.drop
      end

      def previous_page?
        !!@previous_page
      end

      def next_page?
        !!@next_page
      end

      def add_attribute(name:, options:)
        @index.add_attribute_to_schema(name: name, options: options)
      end

      def attributes_present?
        @index.schema.present?
      end
    end
  end
end
