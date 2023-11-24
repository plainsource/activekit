module ActiveKit
  module Base
    class Ensure
      def self.setup_for!(current_class:)
        unless current_class.respond_to? :activekit
          current_class.class_eval do
            def self.activekit
              @activekit ||= ActiveKit::Base::Model.new(current_class: self)
            end
          end
        end
      end
    end
  end
end
