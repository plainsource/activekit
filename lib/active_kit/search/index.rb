module ActiveKit
  module Search
    class Index
      attr_reader :prefix, :schema, :attribute_value_parser

      def initialize(current_class:, describer:)
        @redis = ActiveKit::Search.redis
        @current_class = current_class
        @describer = describer

        current_class_name = current_class.to_s.parameterize.pluralize
        @name = "activekit:search:index:#{current_class_name}"
        @prefix = "activekit:search:#{current_class_name}"
        @schema = {}
        @attribute_value_parser = {}
      end

      def add_attribute_to_schema(name:, options:)
        raise "Error: No type specified for the search attribute #{name}." unless options[:type].present?

        attribute_schema = []

        as = options.delete(:as)
        attribute_schema.push("AS #{as}") unless as.nil?

        type = options.delete(:type)
        attribute_schema.push(type.to_s.upcase) unless type.nil?

        options.each do |key, value|
          if key == :value
            @attribute_value_parser.store(name.to_s, value)
          elsif key.is_a?(Symbol)
            if value == true
              attribute_schema.push(key.to_s.upcase)
            elsif value != false
              attribute_schema.push("#{key.to_s.upcase} #{value.to_s}")
            end
          else
            raise "Invalid option provided to search attribute."
          end
        end

        @schema.store(name.to_s, attribute_schema.join(" "))
      end

      def reload
        current_command = @redis.get("#{@name}:command")
        schema = { "database" => "TAG SORTABLE", "id" => "NUMERIC SORTABLE" }.merge(@schema)
        command = "FT.CREATE #{@name} ON HASH PREFIX 1 #{@prefix}: SCHEMA #{schema.to_a.flatten.join(' ')}"
        unless current_command == command
          drop
          @redis.call(command.split(' '))
          @redis.set("#{@name}:command", command)
          Rails.logger.info "ActiveKit::Search | Index Reloaded: " + "#{@name}:command"
          Rails.logger.debug "=> " + @redis.get("#{@name}:command").to_s
        end
      end

      def drop
        if exists?
          command = "FT.DROPINDEX #{@name}"
          @redis.call(command.split(' '))
          @redis.del("#{@name}:command")
          Rails.logger.info "ActiveKit::Search | Index Dropped: " + @name
        end
      end

      # Redis returns the results in the following form. Where first value is count of results, then every 2 elements are document_id, attributes respectively.
      # [2, "doc:3", ["name", "Grape Juice", "stock_quantity", "4", "minimum_stock", "2"], "doc:4", ["name", "Apple Juice", "stock_quantity", "4", "minimum_stock", "2"]]
      def fetch(term: nil, matching: "*", tags: {}, modifiers: {}, offset: nil, limit: nil, order: nil, page: nil, **options)
        original_term = term

        if term == ""
          results = nil
        elsif self.exists?
          if term.present?
            term.strip!
            term = escape_separators(term)

            case matching
            when "*"
              term = "#{term}*"
            when "%"
              term = "%#{term}%"
            when "%%"
              term = "%%#{term}%%"
            when "%%%"
              term = "%%%#{term}%%%"
            end

            term = " #{term}"
          else
            term = ""
          end

          if tags.present?
            tags = tags.map do |key, value|
              value = value.join("|") if value.is_a?(Array)
              "@#{escape_separators(key)}:{#{escape_separators(value, include_space: true).presence || 'nil'}}"
            end
            tags = tags.join(" ")
            tags = " #{tags}"
          else
            tags = ""
          end

          if modifiers.present?
            modifiers = modifiers.map { |key, value| "@#{escape_separators(key)}:#{escape_separators(value)}" }.join(" ")
            modifiers = " #{modifiers}"
          else
            modifiers = ""
          end

          if (offset.present? || limit.present?) && page.present?
            raise "Error: Cannot specify page and offset/limit at the same time. Please specify one of either page or offset/limit."
          end

          if page.present?
            page = page.to_i.abs

            case page
            when 0
              page = 1
              offset = 0
              limit = 15
            when 1
              offset = 0
              limit = 15
            when 2
              offset = 15
              limit = 30
            when 3
              offset = 45
              limit = 50
            else
              limit = 100
              offset = 15 + 30 + 50 + (page - 4) * limit
            end
          end

          query = "@database:{#{escape_separators(@describer.database.call, include_space: true)}}#{term}#{tags}#{modifiers}"
          command = [
            "FT.SEARCH",
            @name,
            query,
            "LIMIT",
            offset ? offset.to_i : 0, # 0 is the default offset of redisearch in LIMIT 0 10. https://redis.io/commands/ft.search
            limit ? limit.to_i : 10 # 10 is the default limit of redisearch in LIMIT 0 10. https://redis.io/commands/ft.search
          ]
          command.push("SORTBY", *order.split(' ')) if order.present?
          results = @redis.call(command)
          Rails.logger.info "ActiveKit::Search | Index Searched: " + command.to_s
          Rails.logger.debug "=> " + results.to_s
        else
          results = nil
        end

        SearchResult.new(term: original_term, results: results, offset: offset, limit: limit, page: page, current_class: @current_class)
      end

      # List of characters from https://oss.redislabs.com/redisearch/Escaping/
      # ,.<>{}[]"':;!@#$%^&*()-+=~
      def escape_separators(value, include_space: false)
        value = value.to_s

        unless include_space
          pattern = %r{(\'|\"|\.|\,|\;|\<|\>|\{|\}|\[|\]|\"|\'|\=|\~|\*|\:|\#|\+|\^|\$|\@|\%|\!|\&|\)|\(|/|\-|\\)}
        else
          pattern = %r{(\'|\"|\.|\,|\;|\<|\>|\{|\}|\[|\]|\"|\'|\=|\~|\*|\:|\#|\+|\^|\$|\@|\%|\!|\&|\)|\(|/|\-|\\|\s)}
        end

        value.gsub(pattern) { |match| '\\' + match }
      end

      private

      def exists?
        @redis.call("FT._LIST").include?(@name)
      end
    end
  end
end
