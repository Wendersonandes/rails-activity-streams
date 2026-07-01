class ProfilesController < ApplicationController
  before_action :set_profile, only: [ :edit, :update ]

  def show
    redirect_to actor_path(current_actor)
  end

  def edit
    authorize @profile.actor
    states_hash = CS.states(:BR)
    @states = states_hash

    if @profile.state.present?
      code = states_hash.key(@profile.state) || @profile.state
      @cities = CS.cities(code.to_sym, :BR) || []
    else
      @cities = []
    end
  end

  def update
    authorize @profile.actor
    if @profile.update(profile_params)
      redirect_to actor_path(current_actor), notice: "Profile updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_profile
    @profile = current_user.profiles.first!
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "No profile found. Please create one first."
  end

  def profile_params
    params.require(:profile).permit(
      :birthday, :phone, :mobile,
      :address, :city, :state, :country, :zipcode,
      :website, :organization,
      actor_attributes: [ :id, :name, :description, :email ]
    )
  end
end
