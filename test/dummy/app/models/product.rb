class Product < ApplicationRecord
  position_attribute :arrangement
  position_attribute :booking_date_arrangement

  validates :name, presence: true, uniqueness: { case_sensitive: false, allow_blank: true }
end
