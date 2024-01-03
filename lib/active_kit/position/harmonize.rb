module ActiveKit
  module Position
    class Harmonize
      def initialize(current_class:, name:, scope:)
        @current_class = current_class
        @name = name

        @scoped_class = @current_class.where(scope)
        @positioning = Positioning.new
        @batch_size = 1000
      end

      def run!
        @current_class.transaction do
          chair_at_params, scoped_class_with_order, chair_method, offset_operator = control
          currvalue = @positioning.chair_at(**chair_at_params, increase_spot_length_by: 1).first

          first_run = true
          where_offset = nil
          loop do
            records = scoped_class_with_order.where(where_offset).limit(@batch_size)
            break if records.empty?

            records.lock.each do |record|
              value, reharmonize = first_run ? [currvalue, false] : @positioning.public_send(chair_method, currvalue: currvalue)
              raise message_for_reharmonize if reharmonize

              record.send("#{@name}=", value)
              record.save!

              currvalue = record.public_send("#{@name}")
              first_run = false
            end

            where_offset = ["#{@name} #{offset_operator} ?", currvalue]
          end
        end

        Rails.logger.info "ActiveKit::Position | Harmonize for :#{@name}: completed."
      end

      private

      def control
        records = @scoped_class.where.not("#{@name}": nil).reorder("#{@name}": :asc, id: :asc).select(@name.to_sym)
        headtier = records.first&.try(@name.to_sym)&.split("|")&.first&.last&.to_i # returns a tire integer
        foottier = records.last&.try(@name.to_sym)&.split("|")&.first&.last&.to_i # returns a tire integer

        if headtier == foottier
          nexttier, ordering = (headtier == 0) ? [1, :foot_to_head] : [0, :head_to_foot]
        else
          maxitier = (headtier.nil? || foottier.nil?) ? (headtier.nil? ? foottier : headtier) : (headtier > foottier ? headtier : foottier)
          nexttier, ordering = (maxitier + 1), :foot_to_head
        end
        scoped_order, chair_method, offset_operator = (ordering == :head_to_foot) ? [:asc, :chair_below, ">"] : [:desc, :chair_above, "<"]

        scoped_class_with_order = @scoped_class.reorder("#{@name}": scoped_order, id: scoped_order)
        scoped_class_with_order_count = scoped_class_with_order.count
        initial_position = (ordering == :head_to_foot) ? 1 : scoped_class_with_order_count

        chair_at_params = { position: initial_position, tier_no: nexttier, total_count: scoped_class_with_order_count }

        [chair_at_params, scoped_class_with_order, chair_method, offset_operator]
      end

      def message_for_reharmonize
        "Harmonize cannot ask to harmonize again. Please check values of attribute '#{@name}' and try again."
      end
    end
  end
end
