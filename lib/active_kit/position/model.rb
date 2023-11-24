module ActiveKit
  module Position
    class Model
      def initialize(current_class:)
        @current_class = current_class
        @defined_attributes = {}
      end

      def add_attribute(name, options)
        @defined_attributes.store(name.to_sym, options)
      end

      def harmonize!(attribute_name)
        raise message_for(:undefined) unless @defined_attributes.key?(attribute_name.to_sym)
        puts "Harmonizing..."
      end

      def message_for(type)
        case type
        when :undefined
          "Provided attribute name has not been defined as a position_attribute for this model. Please check and try again."
        end
      end
    end
  end
end
