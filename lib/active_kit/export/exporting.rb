module ActiveKit
  module Export
    class Exporting

      def initialize(describer:)
        @describer = describer
      end

      def headings
        @headings ||= @describer.fields.keys.flatten
      end

      def headings?
        headings.present?
      end

      def lines_for(record:)
        row_counter, column_counter = 1, 0

        @describer.fields.inject([[]]) do |rows, (heading, value)|
          if value.is_a? Proc
            rows[0].push(value.call(record))
            column_counter += 1
          elsif value.is_a?(Symbol) || value.is_a?(String)
            rows[0].push(record.public_send(value))
            column_counter += 1
          elsif value.is_a? Array
            deeprows = get_deeprows(record, heading, value, column_counter)
            deeprows.each do |deeprow|
              rows[row_counter] = deeprow
              row_counter += 1
            end

            column_count = get_column_count_for(value)
            column_count.times { |i| rows[0].push(nil) }
            column_counter += column_count
          else
            raise "Could not identify '#{value}' for '#{heading}'."
          end

          rows
        end
      end

      private

      def get_deeprows(record, heading, value, column_counter)
        value_clone = value.clone
        assoc_value = value_clone.shift

        if assoc_value.is_a? Proc
          assoc_records = assoc_value.call(record)
        elsif assoc_value.is_a?(Symbol) || assoc_value.is_a?(String)
          assoc_records = record.public_send(assoc_value)
        else
          raise "Count not identity '#{assoc_value}' for '#{heading}'."
        end

        subrows = []
        assoc_records.each do |assoc_record|
          subrow, subrow_column_counter, deeprows = [], 0, []
          column_counter.times { |i| subrow.push(nil) }

          subrow = value_clone.inject(subrow) do |subrow, v|
            if v.is_a? Proc
              subrow.push(v.call(assoc_record))
              subrow_column_counter += 1
            elsif v.is_a?(Symbol) || v.is_a?(String)
              subrow.push(assoc_record.public_send(v))
              subrow_column_counter += 1
            elsif v.is_a? Array
              deeprows = get_deeprows(assoc_record, heading, v, (column_counter + subrow_column_counter))

              column_count = get_column_count_for(v)
              column_count.times { |i| subrow.push(nil) }
              subrow_column_counter += column_count
            end

            subrow
          end

          subrows.push(subrow)
          deeprows.each { |deeprow| subrows.push(deeprow) }
        end

        subrows
      end

      def get_column_count_for(value)
        count = 0

        value.each do |v|
          unless v.is_a? Array
            count += 1
          else
            count += get_column_count_for(v)
          end
        end

        count - 1
      end
    end
  end
end
