module ActiveKit
  module Sequence1
    class Middleware
      def self.run(request:)
        puts "raising from middleware of activekit sequence."
        # activekit_attribute = ActiveKit::Attribute.where(value: schedule: timestamp < DateTime.now).order(updated_at: :desc)
        # json_where = 'value->"$.schedule.attributes.' + attribute_name.to_s + '" = "' + word_for_position + '"'
        # record_at_position = ActiveKit::Attribute.where(record_type: record.class.name).where(json_where).first&.record
      end
    end
  end
end
