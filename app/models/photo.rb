class Photo < ApplicationRecord
  belongs_to :entry, optional: true

  has_one_attached :file

  validates_presence_of :src

  def url
    if file.attached?
      return Rails.application.routes.url_helpers.rails_blob_url(file, host: Rails.configuration.url)
    end

    src
  end
end
