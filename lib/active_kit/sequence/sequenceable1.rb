require 'active_support/concern'

module ActiveKit
  module Sequence1
    module Sequenceable
      extend ActiveSupport::Concern

      included do
      end

      class_methods do
        # Usage Options
        # sequence_attribute :name
        # sequence_attribute :name, :positioning_method
        # sequence_attribute :name, :positioning_method, updater: {}
        # sequence_attribute :name, :positioning_method, updater: { on: {} }
        # sequence_attribute :name, :positioning_method, updater: { via: :assoc, on: {} }
        # sequence_attribute :name, :positioning_method, updater: { via: {}, on: {} }
        # Note: :on and :via in :updater can accept nested associations.
        def sequence_attribute(name, strict_loading: strict_loading_by_default)
          class_eval <<-CODE, __FILE__, __LINE__ + 1
            def #{name}
              activekit_sequence_attribute_#{name} || build_activekit_sequence_attribute_#{name}
            end

            def #{name}?
              activekit_sequence_attribute_#{name}.present?
            end

            def #{name}=(position)
              self.#{name}.position = position
            end
          CODE

          has_one :"activekit_sequence_attribute_#{name}", -> { where(name: name) }, as: :record, inverse_of: :record, autosave: true, dependent: :destroy, strict_loading: strict_loading, class_name: "ActiveKit::SequenceAttribute"

          scope :"with_activekit_sequence_attribute_#{name}", -> { includes("activekit_sequence_attribute_#{name}") }
        

          # ActiveKit::Base::Ensure.setup_for!(current_class: self)

          # name = name.to_sym
          # options.store(:positioning_method, positioning_method&.to_sym)
          # options.deep_symbolize_keys!

          # set_active_sequence_callbacks(attribute_name: name, options: options)
          # activekiter.sequence.add_attribute(name: name, options: options)
        end

        # Eager load all dependent ActiveKit::SequenceAttribute models in bulk.
        def with_activekit_sequence_attributes
          eager_load(activekit_sequence_attribute_association_names)
        end

        def activekit_sequence_attribute_association_names
          reflect_on_all_associations(:has_one).collect(&:name).select { |n| n.start_with?("activekit_sequence_attribute_") }
        end

        # def set_active_sequence_callbacks(attribute_name:, options:)
        #   positioning_method = options.dig(:positioning_method)
        #   updater = options.dig(:updater) || {}

        #   if updater.empty?
        #     after_save do
        #       position = positioning_method ? self.public_send(positioning_method) : nil
        #       self.class.activekiter.sequence.update(record: self, attribute_name: attribute_name, position: position)
        #       logger.info "ActiveSequence - Sequencing from #{self.class.name}: Done."
        #     end
        #   else
        #     raise ":updater should be a hash while setting sequence_attribute. " unless updater.is_a?(Hash)
        #     raise ":on in :updater should be a hash while setting sequence_attribute. " if updater.key?(:on) && !updater[:on].is_a?(Hash)
        #     raise "Cannot use :via without :on in :updater while setting sequence_attribute. " if updater.key?(:via) && !updater.key?(:on)

        #     updater_via = updater.delete(:via)
        #     updater_on = updater.delete(:on) || updater
            
        #     base_klass = search_base_klass(self.name, updater_via)
        #     klass = reflected_klass(base_klass, updater_on.keys.first)
        #     klass.constantize.class_eval do
        #       after_save    :activekit_sequence_sequenceable_callback
        #       after_destroy :activekit_sequence_sequenceable_callback

        #       define_method :activekit_sequence_sequenceable_callback do
        #         inverse_assoc = self.class.search_inverse_assoc(self, updater_on)
        #         position = positioning_method ? self.public_send(positioning_method) : nil
        #         if inverse_assoc.respond_to?(:each)
        #           inverse_assoc.each { |instance| instance.class.activekiter.sequence.update(record: instance, attribute_name: attribute_name, position: position) }
        #         else
        #           inverse_assoc.class.activekiter.sequence.update(record: inverse_assoc, attribute_name: attribute_name, position: position)
        #         end
        #         logger.info "ActiveSequence - Sequencing from #{self.class.name}: Done."
        #       end
        #       private :activekit_sequence_sequenceable_callback
        #     end
        #   end
        # end

        # def search_base_klass(classname, updater_via)
        #   if updater_via.blank?
        #     classname
        #   elsif updater_via.is_a? Symbol
        #     reflected_klass(classname, updater_via)
        #   elsif updater_via.is_a? Hash
        #     klass = reflected_klass(classname, updater_via.keys.first)
        #     updater_via.values.first.is_a?(Hash) ? search_base_klass(klass, updater_via.values.first) : reflected_klass(klass, updater_via.values.first)
        #   end
        # end

        # def reflected_klass(classname, key)
        #   klass = classname.constantize.reflect_on_all_associations.map { |assoc| [assoc.name, assoc.klass.name] }.to_h[key]
        #   raise "Could not find reflected klass for classname '#{classname}' and key '#{key}' while setting sequence_attribute" unless klass
        #   klass
        # end

        # def search_inverse_assoc(klass_object, updater_on)
        #   if updater_on.values.first.is_a?(Hash)
        #     klass_object = klass_object.public_send(updater_on.values.first.keys.first)
        #     search_inverse_assoc(klass_object, updater_on.values.first)
        #   else
        #     klass_object.public_send(updater_on.values.first)
        #   end
        # end
      end
    end
  end
end
