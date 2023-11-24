module ActiveKit
  module Base
    class Model
      def initialize(current_class:)
        @current_class = current_class
      end

      def position
        @position ||= ActiveKit::Position::Model.new(current_class: @current_class)
      end
    end
  end
end
