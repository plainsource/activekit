module ActiveKit
  module Export
    class Exporter
      attr_reader :describers

      def initialize(current_class:)
        @current_class = current_class
        @describers = {}
      end

      def find_by(describer_name:)
        describer_options = @describers.dig(describer_name)
        return nil unless describer_options.present?

        describer_attributes = describer_options[:attributes]
        hash = {
          name: describer_name,
          kind: describer_options[:kind],
          database: describer_options[:database],
          attributes: describer_attributes,
          includes: describer_attributes.values.map { |options| options.dig(:includes) }.compact.flatten(1).uniq,
          fields: describer_attributes.map { |name, options| [(options.dig(:heading)&.to_s || name.to_s.titleize), (options.dig(:value) || name)] }.to_h
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
