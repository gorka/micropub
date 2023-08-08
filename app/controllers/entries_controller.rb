class EntriesController < ApplicationController
  def index
    @entries = Entry.order(published_at: :desc)
  end

  def show
    @entry = Entry.find(params[:id])
  end
end
