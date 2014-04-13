class MonitoredPeriodsController < ApplicationController
  before_action :set_monitored_period, only: [:edit, :update, :destroy]

  # GET /monitored_periods
  # GET /monitored_periods.json
  def index
    @monitored_periods = MonitoredPeriod.all
  end

  # GET /monitored_periods/1
  # GET /monitored_periods/1.json
  def show
    # do nothing
  end

  # GET /monitored_periods/new
  def new
    @monitored_period = MonitoredPeriod.new
  end

  # GET /monitored_periods/1/edit
  def edit
  end

  # POST /monitored_periods
  # POST /monitored_periods.json
  def create
    @monitored_period = MonitoredPeriod.new(monitored_period_params)
    # @monitored_period.user = current_user

    respond_to do |format|
      if @monitored_period.save
        format.html { redirect_to monitored_periods_path, notice: 'Monitored Period was successfully created.' }
      else
        format.html { render action: 'new' }
      end
    end
  end

  # PATCH/PUT /monitored_periods/1
  # PATCH/PUT /monitored_periods/1.json
  def update
    respond_to do |format|
      if @monitored_period.update(monitored_period_params)
        format.html { redirect_to monitored_periods_path, notice: 'Monitored Period was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @monitored_period.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /monitored_periods/1
  # DELETE /monitored_periods/1.json
  def destroy
    @monitored_period.destroy
    respond_to do |format|
      format.html { redirect_to monitored_periods_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_monitored_period
      @monitored_period = MonitoredPeriod.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white index through.
    def monitored_period_params
      params.require(:monitored_period).permit(:name, :end_date, :start_date)
    end
end
