class Entry < ApplicationRecord
  has_many :photos, dependent: :destroy

  accepts_nested_attributes_for :photos

  def splitted_categories
    return [] unless categories.present?

    categories.split(",").map(&:strip)
  end
end
