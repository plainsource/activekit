module ActiveKit
  class Attribute < ApplicationRecord
    belongs_to :record, polymorphic: true

    store :value, accessors: [ :sequence ], coder: JSON

    validates :value, presence: true, length: { maximum: 1073741823, allow_blank: true }

    before_validation :set_defaults

    private

    def set_defaults
      self.sequence = { attributes: {} } if self.sequence.blank?
    end
  end
end
