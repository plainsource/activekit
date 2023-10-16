require 'active_support/concern'

module ActiveKit
  module Sequence
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
        def sequence_attribute(name, positioning_method, **options)
          name = name.to_sym
          positioning_method = positioning_method.to_sym
          options.deep_symbolize_keys!

          unless self.respond_to?(:sequencer)
            define_singleton_method :sequencer do
              @sequencer ||= ActiveSequence::Sequencer.new(current_class: self)
            end

            has_many :sequence_attributes, as: :record, dependent: :destroy, class_name: "ActiveSequence::Attribute"
            # scope :order_sequence, -> (options_hash) { includes(:sequence_attributes).where(sequence_attributes: { name: name.to_s }).order("sequence_attributes.value": :asc) } 
          end

          set_active_sequence_create_callbacks(attribute_name: name)
          set_active_sequence_commit_callbacks(attribute_name: name, positioning_method: positioning_method, updater: options.delete(:updater))

          sequencer.add_attribute(name: name, options: options)
        end

        def set_active_sequence_create_callbacks(attribute_name:)
          before_create do
            self.sequence_attributes.find_or_initialize_by(name: attribute_name)
            logger.info "ActiveSequence - Creating Sequence attribute '#{attribute}' from #{self.class.name}: Done."
          end
        end

        def set_active_sequence_commit_callbacks(attribute_name:, positioning_method:, updater:)
          updater = updater || {}

          if updater.empty?
            after_commit do
              position = positioning_method ? self.public_send(positioning_method) : nil
              self.class.sequencer.update(record: self, attribute_name: attribute_name, position: position)
              logger.info "ActiveSequence - Sequencing from #{self.class.name}: Done."
            end
          else
            raise ":updater should be a hash while setting sequence_attribute. " unless updater.is_a?(Hash)
            raise ":on in :updater should be a hash while setting sequence_attribute. " if updater.key?(:on) && !updater[:on].is_a?(Hash)
            raise "Cannot use :via without :on in :updater while setting sequence_attribute. " if updater.key?(:via) && !updater.key?(:on)

            updater_via = updater.delete(:via)
            updater_on = updater.delete(:on) || updater
            
            base_klass = search_base_klass(self.class.name, updater_via)
            klass = reflected_klass(base_klass, updater_on.key)
            klass.constantize.class_eval do
              after_commit do
                inverse_assoc = search_inverse_assoc(self, updater_on)
                position = positioning_method ? self.public_send(positioning_method) : nil
                if inverse_assoc.respond_to?(:each)
                  inverse_assoc.each { |instance| instance.class.sequencer.update(record: instance, attribute_name: attribute_name, position: position) }
                else
                  inverse_assoc.class.sequencer.update(record: inverse_assoc, attribute_name: attribute_name, position: position)
                end
                logger.info "ActiveSequence - Sequencing from #{self.class.name}: Done."
              end
            end          
          end
        end

        def search_base_klass(classname, updater_via)
          if updater_via.blank?
            classname
          elsif updater_via.is_a? Symbol
            reflected_klass(classname, updater_via)
          elsif updater_via.is_a? Hash
            klass = reflected_klass(classname, updater_via.key)
            updater_via.value.is_a?(Hash) ? search_base_klass(klass, updater_via.value) : reflected_klass(klass, updater_via.value)
          end
        end

        def reflected_klass(classname, key)
          klass = classname.constantize.reflect_on_all_associations.map { |assoc| [assoc.name, assoc.klass.name] }.to_h[key]
          raise "Could not find reflected klass for classname '#{classname}' and key '#{key}' while setting sequence_attribute" unless klass
          klass
        end

        def search_inverse_assoc(klass_object, updater_on)
          if updater_on.value.is_a?(Hash)
            klass_object = klass_object.public_send(updater_on.value.key)
            search_inverse_assoc(klass_object, updater_on.value)
          else
            klass_object.public_send(updater_on.value)
          end
        end
      end
    end
  end
end
