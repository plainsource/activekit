module ActiveKit
  module Sequence
    class Wordbook
      attr_accessor :bookmark

      def initialize(base: 36, length: 7, gap: 8, bookmark: nil)
        @base = base
        @length = length
        @gap = gap

        @first_letter = 0.to_s(@base)
        @first_word = @first_letter.rjust(@length, @first_letter)

        @last_letter = (@base - 1).to_s(@base)
        @last_word = @last_letter.rjust(@length, @last_letter)

        @bookmark = bookmark || @first_word
      end

      def previous_word(count: 1)
        new_word(direction: :previous, count: count)
      end

      def previous_word?(count: 1)
        previous_word(count: count).present?
      end

      def next_word(count: 1)
        new_word(direction: :next, count: count)
      end

      def next_word?(count: 1)
        next_word(count: count).present?
      end

      def between_word(word_one:, word_two:)
        raise "'#{word_one}' is not in range." if (word_one.length > @length) || (word_one < @first_word || word_one > @last_word)
        raise "'#{word_two}' is not in range." if (word_two.length > @length) || (word_two < @first_word || word_two > @last_word)

        diff = word_one > word_two ? word_one.to_i(@base) - word_two.to_i(@base) : word_two.to_i(@base) - word_one.to_i(@base)
        between_word = (diff / 2).to_s(@base)
        between_word.rjust(@length, @first_letter)
      end

      def between_word?(word_one:, word_two:)
        between_word(word_one: word_one, word_two: word_two).present?
      end

      private

      def new_word(direction:, count:)
        word = @bookmark.to_i(@base)
        word = direction == :next ? word + (count * @gap) : word - (count * @gap)
        word = word.to_s(@base).rjust(@length, @first_letter)
        # TODO: raise exception if word is out of bound before first word or after last word.
        word
      end
    end
  end
end
