require 'rest_client'

class MonitoredResourcesController < ApplicationController
  #before_filter :authenticate_user!
  before_filter :refresh_token!
  before_action :set_monitored_resource, only: [:show, :permissions, :refresh_permissions,
                                                :reports, :permission_groups, :index_structure,
                                                :index_changehistory, :missing_revisions]

  caches_action :show, :format => :json

  def index
    @monitored_resources = current_user.monitored_resources
  end

  def new
    @folders = DriveFiles.retrieve_all_root_folders(current_user.token)
    @monitored_resources_ids = current_user.monitored_resources_ids
    @monitored_resources = current_user.monitored_resources # for navigation only
  end
  
  def create
      @monitored_resource = MonitoredResource.where(monitored_resource_params).first_or_create
      @monitored_resource.update_metadata(current_user.token)
      @monitored_resource.update_permissions(current_user.token)

      redirect_to @monitored_resource, :notice => "New monitored resource '#{@monitored_resource.title}' successfully created"
  end
  
  def show
    respond_to do |format|
      format.html { @mime_count = @monitored_resource.mime_count }
      # format.json { render json: ResourcesDatatable.new(view_context) }
      format.json { render json: @monitored_resource }
    end
  end

  def missing_revisions
    resources = Resource
      .joins('LEFT OUTER JOIN revisions ON resources.id=revisions.resource_id')
      .where('monitored_resource_id=? AND revisions.resource_id IS NULL AND mime_type != "application/vnd.google-apps.folder"',  @monitored_resource.id)

    resources.each do |resource|
      resource.retrieve_revisions(current_user.token)
    end
    redirect_to @monitored_resource, :notice => "Missing Revisions are being refreshed!"
  end

  def permission_groups
    @permission_groups = PermissionGroup.where(monitored_resource_id: @monitored_resource.id)
  end

  def reports

  end

  def index_structure
    @monitored_resource.index_structure(current_user.id, current_user.token, @monitored_resource.gid)
    @monitored_resource.update_attribute(:structure_indexed_at, Time.now) # last indexed at, can be done more than once
    redirect_to @monitored_resource, :notice => "Structure has been indexed: #{@monitored_resource.structure_indexed_at.to_s(:db)}"
  end

  def index_changehistory
    @monitored_resource.index_changehistory(current_user.token)
    @monitored_resource.update_attribute(:changehistory_indexed_at, Time.now)
    redirect_to @monitored_resource, :notice => "Change History has been indexed: #{@monitored_resource.changehistory_indexed_at.to_s(:db)}"
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_monitored_resource
    @monitored_resource = MonitoredResource.where(:id => params[:id], :user_id => current_user.id).first
  end

  # Never trust parameters from the scary internet, only allow the white index through.
  def monitored_resource_params
    par = { :gid => params[:gid], :user_id => current_user.id }
  end
end