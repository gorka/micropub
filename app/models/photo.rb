class Photo < ApplicationRecord
  belongs_to :entry

  has_one_attached :file

  validates_presence_of :src

  def url
    if file.attached?
      return Rails.application.routes.url_helpers.rails_blob_url(file, only_path: true)
    end

    src
  end
end
