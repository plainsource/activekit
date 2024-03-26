require 'active_support/concern'

module ActiveKit
  module Export
    module Exportable
      extend ActiveSupport::Concern

      included do
      end

      class_methods do
        def exporter
          @exporter ||= ActiveKit::Export::Exporter.new(current_class: self)
        end

        def export_attribute(name, **options)
          options.deep_symbolize_keys!
          define_exporter_methods unless exporter.attributes_present?
          exporter.add_attribute(name: name, options: options)
        end

        def define_exporter_methods
          define_singleton_method :to_csv do
            # The 'all' relation must be captured outside the Enumerator,
            # else it will get reset to all the records of the class.
            all_activerecord_relation = all.includes(includes)

            Enumerator.new do |yielder|
              ActiveRecord::Base.connected_to(role: :writing, shard: System::Current.tenant.database.to_sym) do
                # Add the header.
                if header
                  # headings = []
                  # fields.each do |key, value|
                  #   headings << self.exportable_headings(self, key, value)
                  # end
                  # puts headings.inspect
                  # puts headings.flatten.inspect
                  # yielder << CSV.generate_line(headings.flatten)
                end

                # Add the values.
                # find_each will ignore any order if set earlier.
                all_activerecord_relation.find_each do |row|
                  lines = []

                  # new_lines = []
                  # fields.each do |key, value|
                  #   new_lines << self.exportable_lines(self, key, value, row)
                  # end
                  # puts new_lines.inspect
                  # puts "kajlsdlakjsdlaksdjlaksdjlaksjdas"

                  # row_assoc1 = row_assoc2 = nil
                  # line = fields.values.map do |field_value|
                  #   if field_value.is_a? Hash
                  #     row_assoc1 = row.try(field_value.key)
                  #     if field_value.value.is_a? Hash
                  #       row_assoc2 = row.try(field_value.value.key)
                  #       row_assoc2&.instance_eval(field_value.value.value.to_s)
                  #     else
                  #       row_assoc1&.instance_eval(field_value.value.to_s)
                  #     end
                  #   else
                  #     row.instance_eval(field_value.to_s)
                  #   end
                  # end
                  # fields.values.map { |value| row.instance_eval(value) }

                  lines.each do |line|
                    yielder << CSV.generate_line(line)
                  end
                end
              end
            end
          end
        end

        def has_exports1(params)
          params.each do |kind, details|
            if kind == :csv

              define_singleton_method :exportable_headings do |klass, key, value, parent_heading = nil|
                heading = (parent_heading.present? && key.present?) ? "#{parent_heading.to_s} #{key.to_s}" :
                            (parent_heading.present? ? parent_heading.to_s : key.to_s)

                if value.is_a?(String) || value.is_a?(Symbol)
                  heading
                elsif value.is_a?(Hash)
                  multiple_headings = []
                  value.each do |nested_key, nested_value|
                    if nested_key.is_a?(Symbol)
                      nested_key_reflection = klass.reflect_on_association(nested_key)
                      case nested_key_reflection&.macro
                      when :has_many
                        multiple_headings << self.exportable_headings(nested_key_reflection.klass, nil, nested_value, heading)
                      when :has_one
                        multiple_headings << self.exportable_headings(nested_key_reflection.klass, nil, nested_value, heading)
                      when :belongs_to
                        multiple_headings << self.exportable_headings(klass, nil, nested_value, heading)
                      else
                        multiple_headings << self.exportable_headings(klass, nil, nested_value, heading)
                      end
                    else
                      multiple_headings << self.exportable_headings(klass, nested_key, nested_value, heading)
                    end
                  end
                  multiple_headings
                else
                  raise "Invalid value provided for exporting key #{key}."
                end
              end

              define_singleton_method :exportable_lines do |klass, key, value, record|
                if value.is_a?(String) || value.is_a?(Symbol)
                  record&.instance_eval(value.to_s)
                elsif value.is_a?(Hash)
                  multiple_lines = []
                  value.each do |nested_key, nested_value|
                    if nested_key.is_a?(Symbol)
                      nested_key_reflection = klass.reflect_on_association(nested_key)
                      case nested_key_reflection&.macro
                      when :has_many
                        nested_rows = []
                        record.try(nested_key).each do |nested_record|
                          nested_rows << self.exportable_lines(nested_key_reflection.klass, nil, nested_value, nested_record)
                        end
                        multiple_lines << nested_rows
                      when :has_one
                        multiple_lines << self.exportable_lines(nested_key_reflection.klass, nil, nested_value, record.try(nested_key))
                      when :belongs_to
                        multiple_lines << self.exportable_lines(klass, nil, nested_value, record.try(nested_key))
                      else
                        multiple_lines << self.exportable_lines(klass, nil, nested_value, record.try(nested_key))
                      end
                    else
                      multiple_lines << self.exportable_lines(klass, nested_key, nested_value, record)
                    end
                  end
                  multiple_lines
                else
                  raise "Invalid value provided for exporting key #{key}."
                end
              end
            end
          end
        end
      end
    end
  end
end
