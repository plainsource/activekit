module ActiveKit
  module Export
    class Exporter
      attr_reader :schema

      def initialize(current_class:)
        @current_class = current_class
        @schema = {}
      end

      def add_attribute(name:, options:)
        @schema.store(name: name, options: options)
      end

      def attributes_present?
        @schema.present?
      end
    end
  end
end
