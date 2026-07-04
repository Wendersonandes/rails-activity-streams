# Read-only admin listing of {Audience Audiences} (the join between activities and the
# relations they are shared with), paginated. Authorized via {AudiencePolicy}.
#
# @see Audience
class Admin::AudiencesController < ApplicationController
  def index
    @audiences = Audience.includes(:activity, :relation).order(created_at: :desc)
    authorize Audience
    @pagy, @audiences = pagy(@audiences)
  end
end
