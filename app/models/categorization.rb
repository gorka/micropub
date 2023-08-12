class Categorization < ApplicationRecord
  belongs_to :category
  belongs_to :categorizable, polymorphic: true

  accepts_nested_attributes_for :category

  def category_attributes=(hash)
    self.category = Category.find_or_create_by(hash)
  end
end
