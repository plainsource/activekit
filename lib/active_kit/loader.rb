module ActiveKit
  module Loader
    def self.ensure_middleware_for!(request:)
    end

    def self.ensure_setup_for!(current_class:)
      current_class.class_eval do
        unless self.reflect_on_association :activekit_association
          has_one :activekit_association, as: :record, dependent: :destroy, class_name: "ActiveKit::Attribute"

          def activekit
            @activekit ||= Relation.new(current_object: self)
          end

          def self.activekiter
            @activekiter ||= Activekiter.new(current_class: self)
          end
        end
      end
    end

    def self.ensure_has_one_association_for!(record:)
      record.create_activekit_association unless record.activekit_association
    end
  end
end
