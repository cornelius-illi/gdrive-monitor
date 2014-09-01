class DocumentGroupsController < ApplicationController
  before_action :set_document_group, only: [:show, :edit, :update, :destroy]

  # GET /monitored_resources/1/document_groups
  def index
    @monitored_resource = MonitoredResource
      .where(:id => params[:monitored_resource_id])
      .where(:user_id => current_user.id)
      .first()
    @document_groups = DocumentGroup.where(:monitored_resource_id => [:monitored_resource_id])
  end

  # GET /monitored_resources/1/document_groups/1
  def show
  end

  # GET /document_groups/new
  def new
    @monitored_resource = MonitoredResource
      .where(:id => params[:monitored_resource_id])
      .where(:user_id => current_user.id)
      .first()
  end

  def new_samedocument
    @monitored_resource = MonitoredResource
    .where(:id => params[:monitored_resource_id])
    .where(:user_id => current_user.id)
    .first()

    if @monitored_resource.nil?
      redirect_to monitored_resources_path, :notice => "Monitored Resource with ID #{params[:id]} could not be found!"
    end

    @document_group = IdenticalDocument.new
    @document_group.monitored_resource_id = @monitored_resource.id
  end

  # GET /document_groups/1/edit
  def edit
  end

  # POST /document_groups
  # POST /document_groups.json
  def create
    @document_group = DocumentGroup.new(document_group_params)

    respond_to do |format|
      if @document_group.save
        format.html { redirect_to @document_group, notice: 'Document group was successfully created.' }
        format.json { render action: 'show', status: :created, location: @document_group }
      else
        format.html { render action: 'new' }
        format.json { render json: @document_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /document_groups/1
  # PATCH/PUT /document_groups/1.json
  def update
    respond_to do |format|
      if @document_group.update(document_group_params)
        format.html { redirect_to @document_group, notice: 'Document group was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @document_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /document_groups/1
  # DELETE /document_groups/1.json
  def destroy
    @document_group.destroy
    respond_to do |format|
      format.html { redirect_to document_groups_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_document_group
      @monitored_resource = MonitoredResource.find(params[:monitored_resource_id])
      @document_group = DocumentGroup.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def document_group_params
      params[:document_group]
      params.require(:document_group).permit(:monitored_resource_id, :title, :head_id, :resource_ids => [])
    end
end
