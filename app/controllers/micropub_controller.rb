class MicropubController < ApplicationController
  include Micropub::Authenticate

  skip_forgery_protection

  SUPPORTED_MICROFORMATS = %i[ entry ]
  MICROPUB_ACTIONS = %i[ create update delete ]
  UPDATE_ACTIONS = %i[ replace add delete ]
  SUPPORTED_QUERIES = %i[ config source syndicate_to ]

  ENTRY_PROPERTIES = {
    category: :categories,
    content: :content,
    photo: :photos
  }

  def index
    if !params[:q].present? || 
       !SUPPORTED_QUERIES.include?(params[:q].underscore.to_sym)
      head :bad_request
      return
    end

    send("query_#{params[:q].underscore}")
  end

  def create
    if !SUPPORTED_MICROFORMATS.include?(microformat_type) ||
       !MICROPUB_ACTIONS.include?(micropub_action)
      head :bad_request
      return
    end

    case request.content_type
    when /application\/x-www-form-urlencoded/
      send("action_form_encoded_#{micropub_action}")
    when /multipart\/form-data/
      action_form_encoded_multipart_create
    when /application\/json/
      send("action_#{micropub_action}")
    else
      head :bad_request
    end
  end

  private

    def micropub_params
      request.request_parameters.dig(:micropub) ||
      request.request_parameters
    end

    def micropub_action      
      if micropub_params.key?(:action)
        return micropub_params.dig(:action).to_sym
      end

      :create
    end

    def microformat_type
      type = micropub_params.dig(:type)&.first || micropub_params.dig(:h)

      return :entry if !type

      type.sub("h-", "").to_sym
    end

    def parse_json(properties)
      case microformat_type
      when :entry
        create_entry(properties)
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

    # json property parsers

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
        case curr
        when String
          acc << { src: curr }
        when ActionDispatch::Http::UploadedFile
          acc << {
            src: "-",
            file: curr
          }
        else
          acc << {
            src: curr[:value],
            alt: curr[:alt]
          }
        end

        acc
      end
    end

    # json actions

    def action_create(properties = nil)
      item = parse_json(properties || request.params[:properties])

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

    # form-encoded actions

    def action_form_encoded_create(multipart_data = nil)
      properties = multipart_data || params
      entry_properties = properties.select { |key, _| ENTRY_PROPERTIES.keys.include?(key.to_sym) }

      entry_properties.keys.each do |key|
        if !entry_properties[key].is_a?(Array)
          entry_properties[key] = [entry_properties[key]]
        end
      end

      action_create(entry_properties)
    end

    def action_form_encoded_delete
      action_delete
    end

    def action_form_encoded_multipart_create
      action_form_encoded_create(params)
    end

    # query

    def query_config
      data = {
        "syndicate-to": []
      }

      render json: data.to_json, status: :ok
    end

    def query_syndicate_to
      data = {
        "syndicate-to": []
      }

      render json: data.to_json, status: :ok
    end

    def query_source
      if !params[:url].present?
        head :bad_request
        return
      end

      resource = resource_from_url(params[:url])

      data = {
        properties: {}
      }

      if params[:properties].blank?
        data[:type] = [ "h-entry" ]
      end

      properties = params[:properties]&.map(&:to_sym) || []

      if properties.include?(:content) || params[:properties].blank?
        data[:properties][:content] = [ resource.content ]
      end

      if properties.include?(:category) || params[:properties].blank?
        data[:properties][:category] = resource.categories.split(",").map(&:strip)
      end

      if properties.include?(:photo) || params[:properties].blank?
        data[:properties][:photo] = resource.photos.map(&:url)
      end

      render json: data.to_json, status: :ok
    end

    # utils

    def resource_from_url(url)
      url_parts = URI::parse(url).path.split("/").compact_blank
      klass = url_parts.first.classify.constantize
      klass_id = url_parts.second
      klass.find(klass_id)
    end
end
