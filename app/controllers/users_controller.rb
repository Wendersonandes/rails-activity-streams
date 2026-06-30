class UsersController < ApplicationController
  before_action :set_user, only: [ :show, :edit, :update ]

  def show
    authorize @user
  end

  def edit
    authorize @user
  end

  def update
    authorize @user
    if @user.update_with_password(user_params)
      bypass_sign_in(@user) if user_params[:password].present?
      redirect_to account_path, notice: "Account updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:email, :current_password, :password, :password_confirmation)
  end
end
