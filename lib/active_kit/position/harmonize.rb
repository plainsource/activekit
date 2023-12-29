module ActiveKit
  module Position
    class Harmonize
      def initialize(current_class:, name:, scope:)
        @current_class = current_class
        @name = name

        @scoped_class_reversed = @current_class.where(scope).order("#{@name}": :desc, id: :desc)
        @positioning = Positioning.new
        @batch_size = 1000
      end

      # No values in the column
      # 1 value in the column, Some values in the column, 1 less value in the column
      # All values in the column
      def run!
        @current_class.transaction do
          currvalue = @positioning.chair_at(no: @scoped_class_reversed.count, increase_length_by: 1).first
          where_offset = nil

          loop do
            records = @scoped_class_reversed.where(where_offset).limit(@batch_size)
            break if records.empty?

            records.lock.each do |record|
              value, needs_harmonize = @positioning.chair_above(currvalue: currvalue)
              raise "Harmonize cannot ask to harmonize again. Please check values of attribute '#{@name}' and try again." if needs_harmonize

              record.send("#{@name}=", value)
              record.save!
              currvalue = record.public_send("#{@name}")
              where_offset = ["#{@name} > ?", currvalue]
            end
          end
        end

        Rails.logger.info "ActiveKit::Position | Harmonize for :#{@name}: completed."
      end
    end
  end
end
