class PermissionGroupsController < ApplicationController
  before_action :set_permission_group, only: [:edit, :update, :destroy]

  # GET /permission_groups
  # GET /permission_groups.json
  def index
    @permission_groups = PermissionGroup.find(:user_id => current_user.id)
  end

  # GET /permission_groups/1
  # GET /permission_groups/1.json
  def show
    # do nothing
  end

  # GET /permission_groups/new
  def new
    @permission_group = PermissionGroup.new
  end

  # GET /permission_groups/1/edit
  def edit
  end

  # POST /permission_groups
  # POST /permission_groups.json
  def create
    @permission_group = PermissionGroup.new(permission_group_params)
    @permission_group.user = current_user

    respond_to do |format|
      if @permission_group.save
        format.html { redirect_to @permission_group, notice: 'Permission group was successfully created.' }
        format.json { render action: 'show', status: :created, location: @permission_group }
      else
        format.html { render action: 'new' }
        format.json { render json: @permission_group.errors, status: :unprocessable_entity }
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
      @permission_group = PermissionGroup.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def permission_group_params
      params.require(:permission_group).permit(:name)
    end
end
