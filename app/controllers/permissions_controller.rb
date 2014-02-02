class PermissionsController < ApplicationController
  before_action :set_permission, only: [:edit, :update, :destroy]

  # GET /permissions
  # GET /permissions.json
  def index
    @monitored_resource = MonitoredResource.find(params[:monitored_resource_id])
  end

end