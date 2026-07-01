class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  after_action :verify_authorized, unless: :devise_controller?
  after_action :verify_policy_scoped, if: -> { action_name == "index" }, unless: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def current_actor
    @current_actor ||= current_user&.current_profile
  end
  helper_method :current_actor

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :profile_name ])
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end
end
