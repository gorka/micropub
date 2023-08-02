class MicropubController < ApplicationController
  include Micropub::Authenticate

  skip_forgery_protection

  JSON_TYPES = {
    "h-entry": :entry
  }

  MICROPUB_ACTIONS = %i[ create update delete ]
  UPDATE_ACTIONS = %i[ replace add delete ]

  ENTRY_PROPERTIES = {
    category: :categories,
    content: :content,
    photo: :photos
  }

  def create
    if !MICROPUB_ACTIONS.include?(micropub_action)
      head :bad_request
      return
    end

    send("action_#{micropub_action}")
  end

  private

    def micropub_params
      request.params[:micropub]
    end

    def micropub_action
      if micropub_params.key?(:action)
        action_name = micropub_params[:action].to_sym

        if MICROPUB_ACTIONS.include?(action_name)
          return action_name
        else
          return nil
        end
      end

      :create
    end

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
        categories: entry_category(properties),
        photos_attributes: entry_photo(properties)
      }

      Entry.new(data)
    end

    # property parsers

    def entry_category(properties)
      properties[:category]&.join(", ")
    end

    def entry_content(properties)
      content = properties[:content].first

      return content if content.class == String

      return content[:html] if content&.key?(:html)

      "ERROR"
    end

    def entry_photo(properties)
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

    # actions

    def action_create
      item = parse_json

      if item.save
        head :created, location: entry_url(item)
      else
        render json: { errors: "to-do" }, status: :unprocessable_entity
      end
    end

    def action_update
      resource = resource_from_url(micropub_params[:url])

      # get actions to perform
      actions = micropub_params.keys.map(&:to_sym).intersection(UPDATE_ACTIONS)

      # perform actions
      actions.each do |action|
        valid_action_data = micropub_params[action].is_a?(Array) || micropub_params[action].is_a?(ActiveSupport::HashWithIndifferentAccess)

        if !valid_action_data
          head :bad_request
          return
        end

        if action == :delete && micropub_params[action].is_a?(Array)
          micropub_params[action].each do |property|
            update_delete_array(resource, property.to_sym)
          end
        else
          micropub_params[action].keys.each do |property|
            new_value = micropub_params[action][property]

            return unless ENTRY_PROPERTIES.keys.include?(property.to_sym)

            send "update_#{action}", resource, property.to_sym, new_value
          end
        end
      end

      # if url changes, return 201 (:created)
      head :no_content, location: resource
    end

    def action_delete
      resource = resource_from_url(micropub_params[:url])
      resource.destroy!

      head :no_content
    end

    def update_replace(resource, property, value)
      properties = {}
      properties[property] = value

      new_property_value = send "entry_#{property}", properties

      new_params = {}
      new_params[ENTRY_PROPERTIES[property]] = new_property_value

      resource.update!(new_params)
    end

    def update_add(resource, property, value)
      current_value = resource.send(ENTRY_PROPERTIES[property])

      properties = {}
      properties[property] = value

      if property == :category
        current_categories = current_value.present? ? current_value.split(",").map(&:strip) : []
        new_params = {
          categories: current_categories.concat(value).join(", ")
        }

        resource.update!(new_params) if new_params.present?
      end

      if property == :photo
        photos = entry_photo(properties)

        resource.photos.create(photos)
      end
    end

    def update_delete(resource, property, value)
      current_value = resource.send(ENTRY_PROPERTIES[property])

      if property == :category
        current_categories = current_value.present? ? current_value.split(",").map(&:strip) : []
        
        new_params = {
          categories: (current_categories - value).join(", ")
        }

        resource.update!(new_params) if new_params.present?
      end
    end

    def update_delete_array(resource, property)
      if property == :category
        resource.update!({ categories: nil })
      end
    end

    def resource_from_url(url)
      url_parts = URI::parse(url).path.split("/").compact_blank
      klass = url_parts.first.classify.constantize
      klass_id = url_parts.second
      klass.find(klass_id)
    end
end
