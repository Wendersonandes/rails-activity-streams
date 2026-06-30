class Admin::PermissionsController < ApplicationController
  def index
    @permissions = Permission.all.order(:action, :object)
    authorize Permission
  end
end
