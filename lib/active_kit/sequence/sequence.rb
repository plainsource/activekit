module ActiveKit
  module Sequence
    class Sequence
      attr_reader :defined_attributes

      def initialize(current_class:)
        @current_class = current_class

        @defined_attributes = {}
        @wordbook = Wordbook.new
      end

      def update(record:, attribute_name:, position:)
        ActiveKit::Loader.ensure_has_one_association_for!(record: record)

        if position
          raise "position '#{position}' is not a valid unsigned integer value greater than 0." unless position.is_a?(Integer) && position > 0

          wordbook = Wordbook.new
          word_for_position = wordbook.next_word(count: position)
          # TODO: committer record for the attribute with given word_for_position should be found and resaved to recalculate its position.
          # json_where = 'value->"$.sequence.attributes.' + attribute_name.to_s + '" = "' + word_for_position + '"'
          # record_at_position = ActiveKit::Attribute.where(record_type: record.class.name).where(json_where).first&.record
          record.activekit_association.sequence[:attributes][attribute_name.to_sym] = word_for_position
          record.activekit_association.save!
          # record_at_position.save! if record_at_position
        else
          record.activekit_association.sequence[:attributes][attribute_name.to_sym] = nil
          record.activekit_association.save!
        end
      end

      def add_attribute(name:, options:)
        @defined_attributes.store(name, options)
      end
    end
  end
end
