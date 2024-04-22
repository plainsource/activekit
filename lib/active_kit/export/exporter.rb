module ActiveKit
  module Export
    class Exporter
      def initialize(current_class:)
        @current_class = current_class
        @describers = {}
      end

      def create_export_describer(name, options)
        name = name.to_sym
        options.deep_symbolize_keys!

        unless find_describer_by(describer_name: name)
          options.store(:attributes, {})
          @describers.store(name, options)
          describer = find_describer_by(describer_name: name)
          define_describer_method(describer)
        end
      end

      def create_export_attribute(name, options)
        create_export_describer(:to_csv, kind: :csv, database: -> { ActiveRecord::Base.connection_db_config.database.to_sym }) unless @describers.present?

        options.deep_symbolize_keys!

        describer_names = Array(options.delete(:describers))
        describer_names = @describers.keys if describer_names.blank?

        describer_names.each do |describer_name|
          if describer_options = @describers.dig(describer_name)
            describer_options[:attributes].store(name, options)
          end
        end
      end

      private

      def define_describer_method(describer)
        case describer.kind
        when :csv
          @current_class.class_eval do
            define_singleton_method describer.name do
              # The 'all' relation must be captured outside the Enumerator,
              # else it will get reset to all the records of the class.
              all_activerecord_relation = all.includes(describer.includes)

              Enumerator.new do |yielder|
                ActiveRecord::Base.connected_to(role: :writing, shard: describer.database.call) do
                  exporting = exporter.new_exporting(describer: describer)

                  # Add the headings.
                  yielder << CSV.generate_line(exporting.headings) if exporting.headings?

                  # Add the values.
                  # find_each will ignore any order if set earlier.
                  all_activerecord_relation.find_each do |record|
                    lines = exporting.lines_for(record: record)
                    lines.each { |line| yielder << CSV.generate_line(line) }
                  end
                end
              end
            end
          end
        end
      end

      def new_exporting(describer:)
        Exporting.new(describer: describer)
      end

      def find_describer_by(describer_name:)
        describer_options = @describers.dig(describer_name)
        return nil unless describer_options.present?

        describer_attributes = describer_options[:attributes]
        includes = describer_attributes.values.map { |options| options.dig(:includes) }.compact.flatten(1).uniq
        fields = build_describer_fields(describer_attributes)
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
