require "active_support/concern"

module Micropub::Authenticate
  extend ActiveSupport::Concern

  included do
    before_action :authenticate
  end

  private

  def access_token
    params[:access_token]
  end

  def http_token
    authenticate_with_http_token do |token, _options|
      return token
    end
  end

  def authenticate
    if !access_token && !http_token
      head :unauthorized
      return
    end

    if access_token && http_token
      head :bad_request
      return
    end

    token = access_token || http_token

    if token.present?
      headers = {
        "Accept" => "application/json",
        "Authorization" => "Bearer #{token}"
      }
      response = Faraday.get("https://tokens.indieauth.com/token", {}, headers)
      json_response = JSON.parse(response.body).with_indifferent_access

      if response.status == 200 && json_response[:me] == Rails.configuration.url
        return
      end
    end

    head :unauthorized
  end
end
