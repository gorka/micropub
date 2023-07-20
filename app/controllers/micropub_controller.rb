class MicropubController < ApplicationController
  include Micropub::Authenticate

  def create

    head 201, location: "location"
  end
end
