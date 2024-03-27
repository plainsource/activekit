module ActiveKit
  module Export
    class Exporter
      attr_reader :describers

      def initialize(current_class:)
        @current_class = current_class
        @describers = {}
      end

      def find_describer_by(describer_name:)
        describer_options = @describers.dig(describer_name)
        return nil unless describer_options.present?

        describer_attributes = describer_options[:attributes]
        includes = describer_attributes.values.map { |options| options.dig(:includes) }.compact.flatten(1).uniq
        fields = describer_attributes.inject({}) do |fields_hash, (name, options)|
          nested_attributes = Array(options.dig(:attributes))
          if nested_attributes.present?
            nested_attributes.each do |nested_attribute|
              parent_heading = (options.dig(:heading)&.to_s || name.to_s.singularize.titleize) + " "
              parent_value = options.dig(:value) || name
              if nested_attribute.is_a? Hash
                nested_attribute_key, nested_attribute_value = nested_attribute.first.key, nested_attribute.first.value
                fields_hash.store(parent_heading + (nested_attribute_value.dig(:heading)&.to_s || nested_attribute_key.to_s.titleize), { parent_value: parent_value, value: (nested_attribute_value.dig(:value) || nested_attribute_key) })
              else
                fields_hash.store(parent_heading + nested_attribute.to_s.titleize, { parent_value: parent_value, value: nested_attribute })
              end
            end
          else
            fields_hash.store((options.dig(:heading)&.to_s || name.to_s.titleize), (options.dig(:value) || name))
          end

          fields_hash
        end
        hash = {
          name: describer_name,
          kind: describer_options[:kind],
          database: describer_options[:database],
          attributes: describer_attributes,
          includes: includes,
          fields: fields
        }
        OpenStruct.new(hash)
      end

      def new_describer(name:, options:)
        options.store(:attributes, {})
        @describers.store(name, options)
      end

      def describers?
        @describers.present?
      end

      def new_attribute(name:, options:)
        describer_names = Array(options.delete(:describers))
        describer_names = @describers.keys if describer_names.blank?

        describer_names.each do |describer_name|
          if describer_options = @describers.dig(describer_name)
            describer_options[:attributes].store(name, options)
          end
        end
      end
    end
  end
end
