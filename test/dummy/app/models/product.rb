class Product < ApplicationRecord
  position_attribute :arrangement

  export_attribute :name

  validates :name, presence: true, uniqueness: { case_sensitive: false, allow_blank: true }
end
