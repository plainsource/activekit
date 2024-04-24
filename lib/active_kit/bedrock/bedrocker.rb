module ActiveKit
  module Bedrock
    class Bedrocker
      def initialize(current_component:, current_class:)
        @current_component = current_component
        @current_class = current_class
        @describers = {}
      end

      def create_describer(name, options)
        name = name.to_sym
        options.deep_symbolize_keys!

        unless find_describer_by(name: name)
          options.store(:attributes, {})
          @describers.store(name, options)
          @current_class.class_eval <<-CODE, __FILE__, __LINE__ + 1
            def self.#{name}(**params)
              #{@current_component}er.run_describer_method("#{name}", params)
            end
          CODE
        end
      end

      def create_attribute(name, options)
        options.deep_symbolize_keys!

        create_default_describer unless @describers.present?

        describer_names = Array(options.delete(:describers))
        describer_names = @describers.keys if describer_names.blank?

        describer_names.each do |describer_name|
          if describer_options = @describers.dig(describer_name)
            describer_options[:attributes].store(name, options)
          end
        end

        describer_names
      end

      def run_describer_method(describer_name, params)
        raise "Could not find describer while creating describer method." unless describer = find_describer_by(name: describer_name.to_sym)
        describer_method(describer, params)
      end

      def describer_method(describer, params)
        raise NotImplementedError
      end

      def for(describer_name)
        describer_name = @describers.keys[0] if describer_name.nil?
        raise "Could not find any describer name in #{@current_class.name}." if describer_name.blank?

        describer_name = describer_name.to_sym
        raise "Could not find describer '#{describer_name}' in #{@current_class.name}." unless @describers.dig(describer_name)
        componenting = @describers.dig(describer_name, :componenting)
        return componenting if componenting

        @describers[describer_name][:componenting] = "ActiveKit::#{@current_component.to_s.titleize}::#{@current_component.to_s.titleize}ing".constantize.new(describer: find_describer_by(name: describer_name), current_class: @current_class)
        @describers[describer_name][:componenting]
      end

      def get_describer_names
        @describers.keys.map(&:to_s)
      end

      private

      def create_default_describer
        case @current_component
        when :export
          create_describer(:to_csv, kind: :csv, database: -> { ActiveRecord::Base.connection_db_config.database })
        when :search
          create_describer(:limit_by_search, database: -> { ActiveRecord::Base.connection_db_config.database })
        end
      end

      def find_describer_by(name:)
        options = @describers.dig(name)
        return nil unless options.present?

        hash = {
          name: name,
          database: options[:database],
          attributes: options[:attributes]
        }

        if @current_component == :export
          hash.merge!(kind: options[:kind])
          hash.merge!(includes: options[:attributes].values.map { |options| options.dig(:includes) }.compact.flatten(1).uniq)
          hash.merge!(fields: build_describer_fields(options[:attributes]))
        end
        OpenStruct.new(hash)
      end

      def build_describer_fields(describer_attributes)
        describer_attributes.inject({}) do |fields_hash, (name, options)|
          enclosed_attributes = Array(options.dig(:attributes))

          if enclosed_attributes.blank?
            field_key, field_value = (get_heading(options.dig(:heading))&.to_s || name.to_s.titleize), (options.dig(:value) || name)
          else
            field_key, field_value = get_nested_field(name, options, enclosed_attributes)
          end
          fields_hash.store(field_key, field_value)

          fields_hash
        end
      end

      def get_nested_field(name, options, enclosed_attributes, ancestor_heading = nil)
        parent_heading = ancestor_heading.present? ? ancestor_heading : ""
        parent_heading += (get_heading(options.dig(:heading))&.to_s || name.to_s.singularize.titleize) + " "
        parent_value = options.dig(:value) || name

        enclosed_attributes.inject([[], [parent_value]]) do |nested_field, enclosed_attribute|
          unless enclosed_attribute.is_a? Hash
            nested_field_key = parent_heading + enclosed_attribute.to_s.titleize
            nested_field_val = enclosed_attribute

            nested_field[0].push(nested_field_key)
            nested_field[1].push(nested_field_val)
          else
            enclosed_attribute.each do |enclosed_attribute_key, enclosed_attribute_value|
              wrapped_attributes = Array(enclosed_attribute_value.dig(:attributes))
              if wrapped_attributes.blank?
                nested_field_key = parent_heading + (get_heading(enclosed_attribute_value.dig(:heading))&.to_s || enclosed_attribute_key.to_s.titleize)
                nested_field_val = enclosed_attribute_value.dig(:value) || enclosed_attribute_key
              else
                nested_field_key, nested_field_val = get_nested_field(enclosed_attribute_key, enclosed_attribute_value, wrapped_attributes, parent_heading)
              end

              nested_field[0].push(nested_field_key)
              nested_field[1].push(nested_field_val)
            end
          end

          nested_field
        end
      end

      def get_heading(options_heading)
        options_heading.is_a?(Proc) ? options_heading.call(@current_class) : options_heading
      end
    end
  end
end
