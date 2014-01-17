require 'rest_client'

class MonitoredResourcesController < ApplicationController
  #before_filter :authenticate_user!
  before_filter :refresh_token!
  
  def list
    @monitored_resources = current_user.monitored_resources
  end

  def new
    res = DriveFiles.retrieve_all_root_folders(current_user.token)
    @folders = res['items']
    @monitored_resources_ids = current_user.monitored_resources_ids
    p @monitored_resources_ids
  end
  
  def create
    res_id = params[:id]
    unless res_id
      flash[:warning] = "Resource '#{res_id}' could not be found!" 
      redirect_to monitored_resources_list_path
    else
      res = MonitoredResource.find_or_create_by_resource_id_for(res_id, current_user)
      flash[:notice] = "New monitored resource '#{res.head_resource.title}' successfully created"
    
      redirect_to monitored_resources_list_path
    end
  end
  
  def view
    mr_id = params[:id]
    unless mr_id
      flash[:warning] = "Resource '#{gid}' could not be found!" 
      redirect_to monitored_resources_list_path
    end
    
    @monitored_resource = MonitoredResource.find(mr_id)
    unless @monitored_resource.nil?
      child_resources = DriveFiles.retrieve_all_files_for(@monitored_resource.gid, current_user.token)
      Resource.find_create_or_update_batched_for(child_resources, mr_id, current_user.id)
    end
    
    @resources = Resource.find_all_by_monitored_resource_id(mr_id)
  end
end