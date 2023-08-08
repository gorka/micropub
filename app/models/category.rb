class Category < ApplicationRecord
  has_many :categorizations, dependent: :destroy
  has_many :entries, through: :categorizations, source: :categorizable, source_type: "Entry"
end
