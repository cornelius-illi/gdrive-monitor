class PermissionGroupsController < ApplicationController
  before_action :set_permission_group, only: [:edit, :update, :destroy]

  # GET /monitored_resources/1/permission_groups
  def index
    @monitored_resource = MonitoredResource.find(params[:monitored_resource_id])
  end

  # GET /permission_groups/1
  # GET /permission_groups/1.json
  def show
    # do nothing
  end

  # GET /permission_groups/new
  def new
    @monitored_resource = MonitoredResource
      .where(:id => params[:monitored_resource_id])
      .where(:user_id => current_user.id)
      .first()

    if @monitored_resource.nil?
      redirect_to monitored_resources_path, :notice => "Monitored Resource with ID #{params[:id]} could not be found!"
    end

    @permission_group = PermissionGroup.new
    @permission_group.monitored_resource_id = @monitored_resource.id
  end

  # GET /permission_groups/1/edit
  def edit
  end

  # POST /permission_groups
  # POST /permission_groups.json
  def create
    @monitored_resource = MonitoredResource
    .where(:id => params[:permission_group][:monitored_resource_id])
    .where(:user_id => current_user.id)
    .first()

    if @monitored_resource.nil?
      redirect_to monitored_resources_path, :warning => "Monitored Resource with ID #{params[:id]} could not be found!"
    end

    @permission_group = PermissionGroup.new(permission_group_params)

    respond_to do |format|
      if @permission_group.save
        format.html { redirect_to monitored_resource_permission_groups_path(@monitored_resource), notice: "Permission group #{@permission_group.name} was successfully created." }
      else
        format.html { render action: 'new' }
      end
    end
  end

  # PATCH/PUT /permission_groups/1
  # PATCH/PUT /permission_groups/1.json
  def update
    respond_to do |format|
      if @permission_group.update(permission_group_params)
        format.html { redirect_to @permission_group, notice: 'Permission group was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @permission_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /permission_groups/1
  # DELETE /permission_groups/1.json
  def destroy
    @permission_group.destroy
    respond_to do |format|
      format.html { redirect_to permission_groups_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_permission_group
      @monitored_resource = MonitoredResource.find(params[:monitored_resource_id])
      @permission_group = PermissionGroup.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white index through.
    def permission_group_params
      params.require(:permission_group).permit(:name, :monitored_resource_id, :permission_ids => [])
    end
end
