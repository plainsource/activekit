module ActiveKit
  module Search
    class Manager
      def initialize(given_class:, given_describer:)
        @given_class = given_class
        @given_describer = given_describer

        Rails.application.eager_load!
      end

      def reload
        task(name: :reload, log_name: "Reloading")
      end

      def clear
        task(name: :clear, log_name: "Clearing")
      end

      def drop
        task(name: :drop, log_name: "Dropping")
      end

      private

      def task(name:, log_name: "Reloading")
        models = @given_class.present? ? [@given_class] : ActiveRecord::Base.descendants.collect(&:name)
        # Removing these models for efficiency as they will never contain searcher.
        models -= ["ApplicationRecord", "ActionText::Record", "ActionText::RichText", "ActiveKit::ApplicationRecord", "ActionMailbox::Record", "ActionMailbox::InboundEmail", "ActiveStorage::Record", "ActiveStorage::Blob", "ActiveStorage::VariantRecord", "ActiveStorage::Attachment"]
        models.each do |model|
          model_const = model.constantize
          if model_const.try(:searcher)
            describer_names = @given_describer.present? ? [@given_describer] : model_const.searcher.describer_names
            describer_names.each do |describer_name|
              if model_const.searcher.for(describer_name).attributes_present?
                puts "ActiveKit::Search | #{log_name}: #{model}"
                model_const.searcher.for(describer_name).public_send(name)
              end
            end
          end
        end
      end
    end
  end
end
