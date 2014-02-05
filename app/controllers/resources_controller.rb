class ResourcesController < ApplicationController
  before_filter :refresh_token!, only: [:refresh_revisions, :download_revisions]
  before_action :set_resource, only: [:show, :refresh_revisions, :download_revisions,
                                      :calculate_diffs, :merge_revisions, :find_collaborations, :merged_revisions]

  # GET /resources/1
  def show
    # do nothing
  end

  def refresh_revisions
    @resource.retrieve_revisions(current_user.token)
    redirect_to monitored_resource_resource_url(@monitored_resource, @resource), :notice => "Revisions are being refreshed!"
  end

  def download_revisions
    @resource.download_revisions('txt', current_user.token)
    redirect_to monitored_resource_resource_url(@monitored_resource, @resource), :notice => "Revisions are being downloaded!"
  end

  def calculate_diffs
    @resource.calculate_revision_diffs
    redirect_to monitored_resource_resource_url(@monitored_resource, @resource), :notice => "Revision Diffs have been calculated"
  end

  def merge_revisions
    # delete old merges
    Revision.where(:resource_id => @resource.id).update_all('revision_id = NULL')

    # then create new merges
    @resource.merge_weak_revisions
    redirect_to monitored_resource_resource_url(@monitored_resource, @resource), :notice => "Weak Revisions have been merged!"
  end

  def find_collaborations
    # delete old merges
    Revision.where(:resource_id => @resource.id).update_all('collaboration_id = NULL')

    @resource.find_collaborations
    redirect_to monitored_resource_resource_url(@monitored_resource, @resource), :notice => "Collaborations have been created!"
  end

  def merged_revisions
    @master = Revision.find(params[:rev_id])
    @revisions = Revision
      .where('resource_id=? AND ((collaboration_id=? AND revision_id IS NULL) OR (collaboration_id IS NULL AND revision_id=?))',
             @resource.id, params[:rev_id], params[:rev_id] )
      .order('modified_date DESC')

    respond_to do |format|
      format.html { render :layout => !request.xhr? }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_resource
    @monitored_resource = MonitoredResource.find(params[:monitored_resource_id])
    @resource = Resource.find(params[:id])
  end
end
