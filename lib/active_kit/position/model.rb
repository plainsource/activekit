module ActiveKit
  module Position
    class Model
      def initialize(current_class:)
        @current_class = current_class
      end

      def harmonize!(attribute_name)
        puts "Harmonizing..."
      end
    end
  end
end
