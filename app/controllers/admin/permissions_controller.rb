# Read-only admin view of the {Permission} catalog (the fixed set of action/object pairs).
# Authorized via {PermissionPolicy}.
#
# @see Permission
class Admin::PermissionsController < ApplicationController
  def index
    @permissions = Permission.all.order(:action, :object)
    authorize Permission
  end
end
