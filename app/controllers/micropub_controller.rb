class MicropubController < ApplicationController
  include Micropub::Authenticate

  JSON_TYPES = {
    "h-entry": :entry
  }

  def create
    item = parse_json

    if item.save
      head :created, location: entry_url(item)
    else
      render json: { errors: "to-do" }, status: :unprocessable_entity
    end
  end

  private

    def microformat_type(type_array)
      JSON_TYPES[type_array.first.to_sym]
    end

    def parse_json
      type = microformat_type(request.params[:type])
      properties = request.params[:properties]

      case type
      when JSON_TYPES[:"h-entry"]
        create_entry(properties)
      else
        puts "- unknown type"
      end
    end

    def create_entry(properties)
      data = {
        published_at: Time.now,
        content: entry_content(properties),
        categories: entry_categories(properties),
        photos_attributes: entry_photos(properties)
      }

      Entry.new(data)
    end

    # property parsers

    def entry_categories(properties)
      properties[:category]&.join(", ")
    end

    def entry_content(properties)
      content = properties[:content].first

      return content if content.class == String

      return content[:html] if content&.key?(:html)

      "ERROR"
    end

    def entry_photos(properties)
      photos = properties[:photo]

      return [] unless photos.present?

      photos.reduce([]) do |acc, curr|
        if curr.is_a?(String)
          acc << { src: curr }
        else
          acc << {
            src: curr[:value],
            alt: curr[:alt]
          }
        end

        acc
      end
    end
end
