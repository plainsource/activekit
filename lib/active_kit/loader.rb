module ActiveKit
  module Loader
    def self.setup!(current_class:)
      current_class.class_eval do
        unless self.reflect_on_association :activekit
          has_one :activekit, as: :record, dependent: :destroy, class_name: "ActiveKit::Attribute"
        end
      end
    end
  end
end
