class Admin::AudiencesController < ApplicationController
  def index
    @audiences = Audience.includes(:activity, :relation).order(created_at: :desc)
    authorize Audience
    @pagy, @audiences = pagy(@audiences)
  end
end
