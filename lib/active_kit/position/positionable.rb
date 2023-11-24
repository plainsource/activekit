require 'active_support/concern'

module ActiveKit
  module Position
    module Positionable
      extend ActiveSupport::Concern

      included do
      end

      class_methods do
        def position_attribute(name, scope: {})
          ActiveKit::Base::Ensure.setup_for!(current_class: self)

          attribute "#{name}_position", :integer

          validates name, presence: true, uniqueness: { conditions: -> { where(scope) }, case_sensitive: false, allow_blank: true }, length: { maximum: 255, allow_blank: true }
          validates "#{name}_position", numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: lambda { |record| record.public_send("#{name}_position_maximum") + 1 }, allow_blank: true }

          before_validation "#{name}_reposition".to_sym
          after_commit "#{name}_harmonize".to_sym

          class_eval <<-CODE, __FILE__, __LINE__ + 1
            def #{name}_position_in_database
              self.#{name}_positioner.position_in_database
            end

            def #{name}_position_options
              self.#{name}_positioner.position_options
            end

            def #{name}_position_maximum
              self.#{name}_positioner.position_maximum
            end

            private

            def #{name}=(value)
              super(value)
            end

            def #{name}_reposition
              position_maximum_cached = self.#{name}_positioner.position_maximum

              if self.#{name}.blank? && self.#{name}_position.blank?
                self.#{name}_position = position_maximum_cached + 1
              end

              if self.#{name}_position.present? && self.#{name}_position >= 1 && self.#{name}_position <= (position_maximum_cached + 1)
                if self.#{name}_position != #{name}_position_in_database
                  self.#{name} = self.#{name}_positioner.spot_for(position: self.#{name}_position, position_maximum_cached: position_maximum_cached)
                end
              end
            end

            def #{name}_harmonize
              self.#{name}_positioner.harmonize
            end

            def #{name}_positioner
              @#{name}_positioner ||= ActiveKit::Position::Positioner.new(record: self, name: '#{name}', scope: #{scope})
            end
          CODE
        end
      end
    end
  end
end
