class ResourcesController < ApplicationController
  before_action :set_resource, only: [:show]

  # GET /resources/1
  def show
    # do nothing
  end


  private
  # Use callbacks to share common setup or constraints between actions.
  def set_resource
    @resource = Resource.find(params[:id])
  end
end
