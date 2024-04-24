module ActiveKit
  module Export
    class Exporter < Bedrock::Bedrocker
      def describer_method(describer, params)
        case describer.kind
        when :csv
          # The 'all' relation must be captured outside the Enumerator,
          # else it will get reset to all the records of the class.
          all_activerecord_relation = @current_class.all.includes(describer.includes)

          Enumerator.new do |yielder|
            ActiveRecord::Base.connected_to(role: :writing, shard: describer.database.call) do
              exporting = self.for(describer.name)

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
