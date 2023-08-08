class Categorization < ApplicationRecord
  belongs_to :category
  belongs_to :categorizable, polymorphic: true

  accepts_nested_attributes_for :category
end
