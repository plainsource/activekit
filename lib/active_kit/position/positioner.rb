module ActiveKit
  module Position
    class Positioner
      def initialize(record:, name:, scope:)
        @record = record
        @name = name

        @scoped_class = @record.class.where(scope).order("#{@name}": :asc)
        @reharmonize = false
        @positioning = Positioning.new
      end

      def position_in_database
        @scoped_class.where("#{@name}": ..@record.public_send("#{@name}_in_database")).count if @record.public_send("#{@name}_in_database")
      end

      def position_options
        (1..position_maximum).map { |position| [position, "Position #{position}"] }
      end

      def position_maximum
        value = self.maxivalue
        value ? @scoped_class.where("#{@name}": ..value).count : 0
      end

      def spot_for(position:, position_maximum_cached:)
        raise "position or position_maximum_cached cannot be empty for spot_for in activekit." unless position && position_maximum_cached

        edge_position = position_maximum_cached + 1
        if position == edge_position && position == 1
          value, @reharmonize = @positioning.chair_first
        elsif position == edge_position
          value, @reharmonize = @positioning.chair_below(currvalue: self.maxivalue)
        elsif position_in_database.nil?
          value, @reharmonize = @positioning.stool_above(currvalue: currvalue(position, position_maximum_cached),
                                                             prevvalue: prevvalue(position, position_maximum_cached))
        elsif position > position_in_database
          value, @reharmonize = @positioning.stool_below(currvalue: currvalue(position, position_maximum_cached),
                                                             nextvalue: nextvalue(position, position_maximum_cached))
        else
          value, @reharmonize = @positioning.stool_above(currvalue: currvalue(position, position_maximum_cached),
                                                             prevvalue: prevvalue(position, position_maximum_cached))
        end

        value
      end

      def reharmonize?
        @reharmonize
      end

      def reharmonized!
        @reharmonize = false
      end

      private

      def maxivalue
        @scoped_class.last&.public_send(@name)
      end

      def prevvalue(position, position_maximum_cached)
        prevvalue?(position, position_maximum_cached) ? @scoped_class.offset(position - 2).first.public_send(@name) : nil
      end

      def currvalue(position, position_maximum_cached)
        currvalue?(position, position_maximum_cached) ? @scoped_class.offset(position - 1).first.public_send(@name) : nil
      end

      def nextvalue(position, position_maximum_cached)
        nextvalue?(position, position_maximum_cached) ? @scoped_class.offset(position - 0).first.public_send(@name) : nil
      end

      def prevvalue?(position, position_maximum_cached)
        position > 1
      end

      def currvalue?(position, position_maximum_cached)
        position >= 1 && position <= position_maximum_cached
      end

      def nextvalue?(position, position_maximum_cached)
        position < position_maximum_cached
      end
    end
  end
end
