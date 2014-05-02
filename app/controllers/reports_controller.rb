require 'json'

class ReportsController < ApplicationController
  before_action :set_monitored_resource, only: [:index, :generate, :remove]

  META_METRICS = [
    Report::Metrics::NumberOfFilesCreated.title,
    Report::Metrics::NumberOfImages.title,
    Report::Metrics::NumberOfFilesModified.title,
    Report::Metrics::NumberOfFilesPreviousPeriods.title,
    Report::Metrics::NumberAverageFilesCreated.title,
    Report::Metrics::NumberOfGoogleFilesModified.title,
    Report::Metrics::RatioGoogleModifiedFiles.title,
    Report::Metrics::NumberOfRevisions.title,
    Report::Metrics::NumberAverageRevisions.title,
    Report::Metrics::RatioRevisionsModifiedFiles.title,
    Report::Metrics::NumberCollaboratedFiles.title,
    Report::Metrics::NumberGloballyCollaboratedFiles.title,
    Report::Metrics::NumberParallelActivities.title,
    Report::Metrics::NumberParallelGlobalActivities.title
  ].freeze

  def index
    @period_groups = PeriodGroup.all

    authorize! :read, :reports
  end

  def show
  end

  def metareport
    respond_to do |format|

      format.html {
        @period_groups = PeriodGroup.all
        @metrics = META_METRICS

        authorize! :read, :reports
      }

      format.json {
        period_group_id = params[:period_group].to_i
        metric_name = params[:metric]

        period_group = PeriodGroup.find(period_group_id)
        period_names = period_group.monitored_periods.map{ |period| period.name }

        render json: {
          'periods' => period_names,
          'data' => fetch_metareport_data(period_group, metric_name)
        }
      }
    end
  end

  def generate
    PeriodGroup.all.each do |period_group|
      report = Report
        .where(:monitored_resource_id => @monitored_resource.id)
        .where(:period_group_id => period_group.id)
        .first_or_create

      report.generate_report_data
    end

    redirect_to monitored_resource_reports_path(@monitored_resource), :notice => "Reports are being generated! This might take a while!"
  end

  def remove
    @monitored_resource.reports.delete_all
    redirect_to monitored_resource_reports_path(@monitored_resource), :notice => "All previous reports have successfully been deleted!"
  end

  # @todo: to implement/ refactor
  def mime_types
    @mime_count = Hash.new

    mime_types = Resource.select(:mime_type).uniq
    mime_types.each do |r|
      @mime_count[r.mime_type] = Resource.where(:mime_type => r.mime_type).count
    end

    @mime_count.sort_by {|_key, value| value}
  end

  def resources_without_checksum
    # list all resources without checksum, group by type
  end

  def comments_by_mime_type

  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_monitored_resource
    @monitored_resource = MonitoredResource
      .where(:id => params[:monitored_resource_id]).first

    # Authorize object permission - @todo: better way to solve this via cancan?
    shared = current_user.shared_resources.map {|r| r.id }
    @monitored_resource = nil unless ((@monitored_resource.user_id == current_user.id) || shared.include?(@monitored_resource.id))

    # CANCAN - authorize read access
    authorize! :read, @monitored_resource
  end

  def use_in_metareport?(metric_name)
    return META_METRICS.include?(metric_name)
  end

  def generate_metareport

    meta_report_data = Hash.new

    PeriodGroup.all.each do |period_group|

      meta_report_data[period_group.name] = Hash.new
      teams = { 1 => 'Siemens', 2 => 'Lapeyre', 4 => 'Bayer'}

      [1,2,4].each do |monitored_resource_id|
        report = Report
        .where(:period_group_id => period_group.id)
        .where(:monitored_resource_id => monitored_resource_id)
        .first

        report.data.each do |chapter_index, chapter|
          chapter[:values].each do |section|
            section[:values].each do |metric|
              metric_name = metric[:name]
              if use_in_metareport?(metric_name)
                meta_report_data[period_group.name][metric_name] = Array.new unless meta_report_data[period_group.name].has_key?(metric_name)

                # line-diagram: ['periods','team-name1',...], [period-name, team:1, team:2, team:4]
                #nbr_periods = length-1
                #period_group.monitored_periods.each_with_index do |period,p_index|
                #  period_array = Array.new
                #  period_array << period.name
                #end

                # stacked-column: [team-name, +values for all periods ... ]
                tvalues = metric[:values]
                tvalues.insert(0, teams[monitored_resource_id])
                meta_report_data[period_group.name][metric_name] << tvalues

              end
            end
          end
        end # report.data
      end # monitored resources
    end

    return meta_report_data
  end

  def fetch_metareport_data(period_group, metric_name)
    # [ {'name' => 'Team-Name', 'data' => [values-by-period]}, {}]
    meta_report_data = Array.new

    reports = Report
      .where(:period_group_id =>  period_group.id)
      .where('monitored_resource_id IN (1,2,4)')
      .order('monitored_resource_id ASC')

    reports.each do |report|
      monitored_resource = MonitoredResource.find(report.monitored_resource_id)
      results_for_resource = Hash.new
      results_for_resource['name'] = monitored_resource.title
      results_for_resource['data'] = Array.new

      report.data.each do |chapter_index, chapter|
        chapter[:values].each do |section|
          section[:values].each do |metric|
            if metric_name.eql? metric[:name]
              results_for_resource['data'] = metric[:values]
            end
          end
        end
      end

      meta_report_data << results_for_resource
    end

    return meta_report_data
  end

  def generate_metareport_line

    meta_report_data = Hash.new

    PeriodGroup.all.each do |period_group|
      meta_report_data[period_group.name] = Hash.new

      reports = Report
        .where(:period_group_id =>  period_group.id)
        .where('monitored_resource_id IN (1,2,4)')
        .order('monitored_resource_id ASC')

      META_METRICS.each do |metric_name|
        meta_report_data[period_group.name][metric_name] = Array.new
        meta_report_data[period_group.name][metric_name] << ['Period Name', 'Siemens', 'Lapeyre', 'Bayer']

        period_group.monitored_periods.each_with_index do |period, period_index|
          period_array = [period.name]

          reports.each do |report|
            report.data.each do |chapter_index, chapter|
              chapter[:values].each do |section|
                section[:values].each do |metric|
                  if metric_name.eql? metric[:name]
                    period_array << metric[:values][period_index]
                  end
                end
              end
            end
          end

          meta_report_data[period_group.name][metric_name] << period_array

        end
      end
    end

    return meta_report_data
  end
end
