require 'rest_client'

class MonitoredResourcesController < ApplicationController
  #before_filter :authenticate_user!
  before_filter :refresh_token!
  before_action :set_monitored_resource, only: [:show, :permissions, :refresh_permissions, :reports]
  
  def list
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
    unless @monitored_resource.nil?
      unless @monitored_resource.structure_indexed? || @monitored_resource.changehistory_indexed?
        flash[:warning] = "Structure/ Change History  has not been indexed, yet!"
      end

      # @todo: migrate to delayed task
      # child_resources = DriveFiles.retrieve_all_files_for(@monitored_resource.gid, current_user.token)
      # Resource.find_create_or_update_batched_for(child_resources, mr_id, current_user.id)
    end
  end

  def permissions
  end

  def refresh_permissions
    unless @monitored_resource.blank?
      @monitored_resource.update_permissions(current_user.token)
      redirect_to mr_permissions_path, :notice => "Permissions refreshed!"
    end
  end

  def reports

  end

  def index_structure

  end

  def index_changehistory

  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_monitored_resource
    @monitored_resource = MonitoredResource.where(:id => params[:id], :user_id => current_user.id).first
    @monitored_resources = current_user.monitored_resources # for navigation only
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def monitored_resource_params
    par = { :gid => params[:gid], :user_id => current_user.id }
  end
end