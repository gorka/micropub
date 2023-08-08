class Entry < ApplicationRecord
  include Categorizable

  has_many :photos, dependent: :destroy

  accepts_nested_attributes_for :photos
end
