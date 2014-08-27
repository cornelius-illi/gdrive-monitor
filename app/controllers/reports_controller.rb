require 'json'

class ReportsController < ApplicationController
  before_action :set_monitored_resource, only: [:index, :generate, :show, :remove]

  META_METRICS = [
    Report::Metrics::NumberWorkingDays.title,
    Report::Metrics::PercentageWorkingDays.title,
    Report::Metrics::NumberOfFilesCreated.title,
    Report::Metrics::NumberOfImages.title,
    Report::Metrics::NumberOfFilesModified.title,
    Report::Metrics::NumberOfFilesPreviousPeriods.title,
    Report::Metrics::PercentageGdInWd.title,
    Report::Metrics::NumberOfRevisions.title,
    Report::Metrics::NumberCollaboratedFiles.title,
    Report::Metrics::NumberGloballyCollaboratedFiles.title,
    Report::Metrics::SumGlobalCollaborationActivities.title,
    Report::Metrics::NumberCollaborativeSessions.title,
    Report::Metrics::NumberGlobalCollaborativeSessions.title,
    Report::Metrics::SumActivities.title,
    Report::Metrics::RatioActivitiesWorkdays.title
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
        metric_name = params[:metric]
        periods = MonitoredPeriod.all.order(start_date: :asc)
        period_names = periods.map{ |period| period.name }
        period_days = periods.map{ |period| period.days }
        period_hash = { :name => 'Days/ Period', :data => period_days}

        data = fetch_metareport_data(metric_name)
        data.insert(0,period_hash)

        render json: {
          'periods' => period_names,
          'data' => data
        }
      }
    end
  end

  def generate
    single = true

    Report.delete("monitored_resource_id = #{@monitored_resource.id}")

    if single
      report = Report
      .where(:monitored_resource_id => @monitored_resource.id)
      .first_or_create
      report.generate_report_data
    else
      PeriodGroup.all.each do |period_group|
        report = Report
        .where(:monitored_resource_id => @monitored_resource.id)
        .where(:period_group_id => period_group.id)
        .first_or_create

        report.generate_report_data
      end
    end


    redirect_to monitored_resource_reports_path(@monitored_resource), :notice => "Reports are being generated! This might take a while!"
  end

  def remove
    @monitored_resource.reports.delete_all
    redirect_to monitored_resource_reports_path(@monitored_resource), :notice => "All previous reports have successfully been deleted!"
  end

  def statistics
    respond_to do |format|
      format.html {
        @dates = Resource.timespan
        @resource_count = Resource.where("mime_type != '#{Resource::GOOGLE_FOLDER_TYPE}'").count
        @revisions_count = Revision.count
        @revision_google_count = Revision.count_revisions_google_files
        @google_count = Resource.count_google_resources
        @office_count = Resource.count_office_resources
        @openoffice_count = Resource.count_openoffice_resources
        @images_count = Resource.count_images
        @resource_single = Resource.with_single_revision
        @resource_single_images = Resource.with_single_images
        @resource_single_same_latest = Resource.with_single_revision_same_latest
        @resource_single_different_latest = Resource.with_single_revision_different_latest
        @resource_single_latest_eql_one = Resource.with_single_revision_latest_eql_one

        @mime_count = Resource.topten_mime_types
      }
      format.json {
        render json: Resource.topten_mime_types_revisions_box_plot
      }
    end
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

  def fetch_metareport_data(metric_name)
    # [ {'name' => 'Team-Name', 'data' => [values-by-period]}, {}]
    meta_report_data = Array.new

    reports = Report
      .where('monitored_resource_id IN (1,2,4)')
      .order('monitored_resource_id ASC')

    reports.each do |report|
      monitored_resource = MonitoredResource.find(report.monitored_resource_id)
      results_for_resource = Hash.new
      results_for_resource['name'] = monitored_resource.anonymous_title
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
