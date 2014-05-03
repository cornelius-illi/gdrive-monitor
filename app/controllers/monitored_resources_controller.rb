require 'rest_client'
require 'time_diff'

class MonitoredResourcesController < ApplicationController
  #before_filter :refresh_token!, only: [:new, :index_structure]
  before_action :set_monitored_resource, only: [:show, :permission_groups, :index_structure, :combine_revisions]

  def index
    @monitored_resources = current_user.monitored_resources
  end

  def new
    authorize! :manage, @monitored_resource
    refresh_token!

    @folders = DriveFiles.retrieve_all_root_folders(current_user.token)
    @monitored_resources_ids = current_user.monitored_resources_ids
    @monitored_resources = current_user.monitored_resources # for navigation only
  end
  
  def create_with
    authorize! :create, @monitored_resource
    @monitored_resource = MonitoredResource.where(monitored_resource_params).first_or_create
    @monitored_resource.update_metadata(current_user.token)
    @monitored_resource.update_permissions(current_user.token)

    redirect_to @monitored_resource, :notice => "New monitored resource '#{@monitored_resource.title}' successfully created"
  end
  
  def show
    respond_to do |format|
      format.html {
        # wrong parameter passed -> return
        redirect_to root_path, :alert => "The resource does not exist!" if @monitored_resource.blank?
      }
      format.json { render json: ResourcesDatatable.new(view_context, @monitored_resource) }
      #format.json { render json: @monitored_resource }
    end
  end

  def index_structure
    authorize! :manage, @monitored_resource
    refresh_token!

    @monitored_resource.update_metadata(current_user.token)
    @monitored_resource.index_structure(current_user.id, current_user.token, @monitored_resource.gid)

    now = Time.now
    diff = Time.diff(@monitored_resource.structure_indexed_at, now)
    @monitored_resource.update_attribute(:structure_indexed_at, now)

    redirect_to @monitored_resource, :notice => "Structure has last been indexed #{diff[:diff]} hours ago!"
  end

  def combine_revisions
    authorize! :manage, @monitored_resource

    @monitored_resource.combine_revisions
    redirect_to @monitored_resource, :notice => "Revisions are being combined! This might take a while!"
  end

  def grant_access

  end

  # @TODO DEPRECATED - SHOULD BE REMOVED IF NO LONGER NEEDED

  # Downlaods revisions for files that have none (revisions.eql? 0)
  # can be removed once the 401 - unauthorized request can be handled!
  def missing_revisions
    resources = Resource
    .joins('LEFT OUTER JOIN revisions ON resources.id=revisions.resource_id')
    .where('monitored_resource_id=? AND revisions.resource_id IS NULL AND mime_type != "application/vnd.google-apps.folder"',  @monitored_resource.id)

    resources.each do |resource|
      resource.retrieve_revisions(current_user.token)
    end
    redirect_to @monitored_resource, :notice => "Missing Revisions are being refreshed!"
  end

  def download_revisions
    @monitored_resource.resources.google_resources.each do |resource|
      # each function call will result in a new delayed job, each revision download in another one
      resource.download_revisions(current_user.token)
    end
    redirect_to @monitored_resource, :notice => "Revisions are being downloaded! This might take a while!"
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_monitored_resource
    @monitored_resource = MonitoredResource
      .where(:id => params[:id]).first

    # wrong parameter passed -> return
    return nil if @monitored_resource.blank?

    # Authorize object permission - @todo: better way to solve this via cancan?
    shared = current_user.shared_resources.map {|r| r.id }
    @monitored_resource = nil unless ((@monitored_resource.user_id == current_user.id) || shared.include?(@monitored_resource.id))

    # CANCAN - authorize read access
    authorize! :read, @monitored_resource
  end

  # Never trust parameters from the scary internet, only allow the white index through.
  def monitored_resource_params
    par = { :gid => params[:gid], :user_id => current_user.id }
  end
end