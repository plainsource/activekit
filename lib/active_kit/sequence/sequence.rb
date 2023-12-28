module ActiveKit
  module Sequence
    class Sequence
      attr_reader :defined_attributes

      def initialize(current_class:)
        @current_class = current_class
        @defined_attributes = {}
      end

      def update(record:, attribute_name:, position:)
        sequence_attribute = ensure_association_for!(record: record, attribute_name: attribute_name)

        if position
          raise "position '#{position}' is not a valid unsigned integer value greater than 0." unless position.is_a?(Integer)

          sequence_attribute.position = position
          raise "position '#{position}' is not valid between 1 and #{sequence_attribute.position_maximum_count}." unless sequence_attribute.position_in_range?

          sequence_attribute.save!
        end
      end

      def add_attribute(name:, options:)
        @defined_attributes.store(name.to_sym, options)
      end

      private

      def ensure_association_for!(record:, attribute_name:)
        record.activekit_sequence_attributes.find_by(name: attribute_name) || record.activekit_sequence_attributes.create!(name: attribute_name)
      end
    end
  end
end
