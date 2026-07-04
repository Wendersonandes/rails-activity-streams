# Read-only admin inspection of {Tie Ties} (the materialized links of the social graph),
# listing and showing individual ties. Authorized via {TiePolicy}.
#
# @see Tie
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
