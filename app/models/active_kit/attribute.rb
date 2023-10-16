module ActiveKit
  class Attribute < ApplicationRecord
    belongs_to :record, polymorphic: true

    validates :value, presence: true, length: { maximum: 1073741823, allow_blank: true }
  end
end
