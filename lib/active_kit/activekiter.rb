module ActiveKit
  class Activekiter
    def initialize(current_class:)
      @current_class = current_class
    end

    def sequence
      @sequence ||= ActiveKit::Sequence::Sequence.new(current_class: @current_class)
    end
  end
end
