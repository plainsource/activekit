module ActiveKit
  module Search
    class Key
      def initialize(index:)
        @redis = ActiveKit::Search.redis
        @index = index
      end

      def reload(record:)
        clear(record: record)

        hash_key = key(record: record)
        hash_value = { "database" => System::Current.tenant.database, "id" => record.id }
        @index.schema.each do |field_name, field_value|
          attribute_name = field_name
          attribute_value = @index.attribute_value_parser[field_name]&.call(record) || record.public_send(field_name)
          attribute_value = field_value.downcase.include?("tag") ? attribute_value : @index.escape_separators(attribute_value)
          hash_value.store(attribute_name, attribute_value)
        end
        @redis.hset(hash_key, hash_value)
        Rails.logger.info "ActiveKit::Search | Key Reloaded: " + hash_key
        Rails.logger.debug "=> " + @redis.hgetall("#{hash_key}").to_s
      end

      def clear(record:)
        hash_key = key(record: record)
        drop(keys: hash_key)
      end

      def drop(keys:)
        return unless keys.present?
        if @redis.del(keys) > 0
          Rails.logger.info "ActiveKit::Search | Keys Removed: " + keys.to_s
        end
      end

      private

      def key(record:)
        "#{@index.prefix}:#{System::Current.tenant.database}:#{record.id}"
      end
    end
  end
end
