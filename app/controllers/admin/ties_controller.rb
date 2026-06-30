class Admin::TiesController < ApplicationController
  def index
    @ties = Tie.includes(:contact, :relation).order(created_at: :desc)
    authorize Tie
    @pagy, @ties = pagy(@ties)
  end

  def show
    @tie = Tie.find_by!(id: params[:id])
    authorize @tie
  end
end
