module ActiveKit
  module Schedule
    class Schedule
      attr_reader :defined_attributes

      def initialize(current_class:)
        @current_class = current_class

        @defined_attributes = {}
      end

      def add(record:, attribute_name:, datetime:, method:)
        ActiveKit::Base::Ensure.has_one_association_for!(record: record)

        record.activekit_association.schedule[:attributes][attribute_name.to_sym] = nil
        record.activekit_association.save!
      end

      def add_attribute(name:, options:)
        @defined_attributes.store(name, options)
      end
    end
  end
end
