class PermissionsController < ApplicationController
  before_action :set_monitored_resource

  # GET /monitored_resources/1/permissions
  def index
  end

  # GET monitored_resources/1/permissions/refresh
  def refresh
    # updates all permissions that are found on root resource
    @monitored_resource.update_permissions(current_user.token)
    redirect_to monitored_resource_permissions_path(@monitored_resource), :notice => "Permissions are being refreshed!"
  end

  private
  def set_monitored_resource
    @monitored_resource = MonitoredResource.find(params[:monitored_resource_id])
  end
end