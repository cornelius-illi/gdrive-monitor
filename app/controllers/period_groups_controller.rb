class PeriodGroupsController < ApplicationController
  before_action :set_period_group, only: [:edit, :update, :destroy]

  def index
    @period_groups = PeriodGroup.all
  end

  def new
    @period_group = PeriodGroup.new
    @monitored_periods = MonitoredPeriod.all.ungrouped
  end

  def edit
    @monitored_periods = MonitoredPeriod.all
  end

  def update
    respond_to do |format|
      if @period_group.update(period_group_params)
        format.html { redirect_to period_groups_path, notice: 'Period-Group was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @period_group.errors, status: :unprocessable_entity }
      end
    end
  end

  def create
    @period_group = PeriodGroup.new(period_group_params)
    # @monitored_period.user = current_user

    respond_to do |format|
      if @period_group.save
        format.html { redirect_to period_groups_path, notice: 'Period-Group was successfully created.' }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def destroy
    @period_group.destroy
    respond_to do |format|
      format.html { redirect_to period_groups_path }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_period_group
    @period_group = PeriodGroup.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white index through.
  def period_group_params
    params.require(:period_group).permit(:name, :logo_class, :monitored_period_ids => [])
  end
end
