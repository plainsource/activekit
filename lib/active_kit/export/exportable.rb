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

        def export_describer(name, **options)
          name = name.to_sym
          options.deep_symbolize_keys!

          unless exporter.find_describer_by(describer_name: name)
            exporter.new_describer(name: name, options: options)
            define_export_describer_method(kind: options[:kind], name: name)
          end
        end

        def export_attribute(name, **options)
          export_describer(:to_csv, kind: :csv, database: -> { ActiveRecord::Base.connection_db_config.database.to_sym }) unless exporter.describers?

          options.deep_symbolize_keys!
          exporter.new_attribute(name: name.to_sym, options: options)
        end

        def define_export_describer_method(kind:, name:)
          case kind
          when :csv
            define_singleton_method name do
              describer = exporter.find_describer_by(describer_name: name)
              raise "could not find describer for the describer name '#{name}'" unless describer.present?

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
    end
  end
end
