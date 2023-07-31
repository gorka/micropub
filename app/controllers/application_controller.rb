class ApplicationController < ActionController::Base
  rescue_from Micropub::Authenticate::Unauthorized, with: :micropub_unauthorized

  private
    def micropub_unauthorized
      head :unauthorized
    end
end
