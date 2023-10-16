module ActiveKit
  module Sequence
    class Sequencer
      attr_reader :defined_attributes

      def initialize(current_class:)
        @current_class = current_class

        @defined_attributes = {}
        @wordbook = Wordbook.new
      end

      def update(record:, attribute_name:, position:)
        attribute = Attribute.find_by(record: record, name: attribute_name)
        Attribute.create!(record: record, name: attribute_name) unless attribute

        if position
          raise "position '#{position}' is not a valid unsigned integer value greater than 0." unless position.is_a?(Integer) && position > 0

          attribute_at_position = Attribute.where(record_type: record.class.name, name: attribute_name).order(value: :asc).offset(position - 1).limit(1)
          attribute

          wordbook = Wordbook.new
          total_position_count = Attribute.where(record_type: record.class.name, name: attribute_name).order(value: :asc).count
          if attribute == attribute_at_position(position)
            return
          elsif position == 1

          elsif position == total_position_count
            wordbook.bookmark = attribute_at_position(total_position_count).value

            attribute.value = wordbook.next_word if wordbook.next_word?
            attribute.save!
          elsif position > total_position_count
            maximum_word = Attribute.where(record_type: record.class.name, name: attribute_name).maximum(:value)

            wordbook.bookmark = maximum_word
            attribute.value = wordbook.next_word if wordbook.next_word?
            attribute.save!
          elsif position < total_position_count

          end
        end
      end

      def rebalance_from(position:)
        ActiveRecord::Base.transaction do
          wordbook = Wordbook.new
          Attribute.where(record_type: record.class.name, name: attribute_name).order(value: :asc).offset(position - 1).limit(1)
          Attribute.where(record_type: record.class.name, name: attribute_name).order(value: :asc).offset(position - 1).each do |attribute|
            wordbook.bookmark = attribute.value
            raise "Could not find next word in wordbook while rebalancing" unless wordbook.next_word?

            attribute.value = wordbook.next_word
            attribute.save!
          end
        end
      end

      def attribute_at_position(position)
        Attribute.where(record_type: record.class.name, name: attribute_name).order(value: :asc).offset(position - 1).limit(1)
      end

      def add_attribute(name:, options:)
        @defined_attributes.store(name, options)
      end
    end
  end
end
