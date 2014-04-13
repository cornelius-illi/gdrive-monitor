class ReportsController < ApplicationController
  before_action :set_monitored_resource, only: [:index, :generate, :remove]

  def index
    @period_groups = PeriodGroup.all
  end

  def show
  end

  def generate
    MonitoredPeriod.all.each do |period|
      report = Report
        .where(:monitored_resource_id => @monitored_resource.id)
        .where(:monitored_period_id => period.id)
        .first_or_create

      # report are not recalculated by default
      next unless report.data.blank?

      report.generate_report_data
    end

    redirect_to monitored_resource_reports_path(@monitored_resource), :notice => "Reports are being generated! This might take a while!"
  end

  def remove
    @monitored_resource.reports.delete_all
    redirect_to monitored_resource_reports_path(@monitored_resource), :notice => "All previous reports have successfully been deleted!"
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_monitored_resource
    @monitored_resource = MonitoredResource.where(:id => params[:monitored_resource_id], :user_id => current_user.id).first
  end
end
