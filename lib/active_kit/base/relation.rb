module ActiveKit
  module Base
    class Relation
      def initialize(current_object:)
        @current_object = current_object
      end
    end
  end
end
