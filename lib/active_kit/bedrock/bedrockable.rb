require 'active_support/concern'

module ActiveKit
  module Bedrock
    module Bedrockable
      def self.extended(base)
        current_component = base.name.deconstantize.demodulize.downcase

        base.module_eval <<-CODE, __FILE__, __LINE__ + 1
          module ClassMethods
            def #{current_component}er
              @#{current_component}er ||= ActiveKit::#{current_component.to_s.titleize}::#{current_component.to_s.titleize}er.new(current_component: :#{current_component}, current_class: self)
            end

            private

            def #{current_component}_describer(name, **options)
              #{current_component}er.create_describer(name, options)
            end

            def #{current_component}_attribute(name, **options)
              #{current_component}er.create_attribute(name, options)
            end
          end
        CODE
      end
    end
  end
end
