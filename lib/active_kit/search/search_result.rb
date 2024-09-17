module ActiveKit
  module Search
    class SearchResult
      attr_reader :term, :count, :documents, :keys, :ids, :records, :current_page, :previous_page, :next_page

      def initialize(term:, results:, offset:, limit:, page:, current_class:)
        @term = term

        if results
          @count = results.shift
          @documents = results.each_slice(2).map { |key, attributes| [key, attributes.each_slice(2).to_h] }.to_h

          if page.present?
            @current_page = page
            @previous_page = @current_page > 1 ? (@current_page - 1) : nil
            @next_page = (offset + limit) < count ? (@current_page + 1) : nil
          end
        else
          @count = 0
          @documents = {}
        end

        @keys = @documents.keys
        @ids = @documents.map { |key, value| key.split(":").last }

        # Return records from database.
        # This also ensures that any left over document_ids in redis that have been deleted in the database are left out of the results.
        # This orders the records in the order of executed search.
        @records = current_class.where(id: ids).reorder(Arel.sql("FIELD(#{current_class.table_name}.id, #{ids.join(', ')})"))
      end
    end
  end
end
