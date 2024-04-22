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
          exporter.create_describer(name, options)
        end

        def export_attribute(name, **options)
          exporter.create_attribute(name, options)
        end

        def export_describer_method(describer)
          case describer.kind
          when :csv
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
