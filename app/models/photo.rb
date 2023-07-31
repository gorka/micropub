class Photo < ApplicationRecord
  belongs_to :entry

  validates_presence_of :src
end
