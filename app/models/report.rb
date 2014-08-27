class Report < ActiveRecord::Base
  belongs_to  :monitored_resource
  belongs_to  :period_group
  
  serialize :data, Hash

  # *** DELAYED TASKS - START
  def generate_report_data
    return if monitored_resource_id.blank?

    # initialize here
    chapters = Array.new
    chapters << Report::Chapters::OverallStatisticsChapter.new
    chapters << Report::Chapters::PermissionBasedChapter.new
    chapters << Report::Chapters::PermissionGroupBasedChapter.new

    monitored_resource ||= MonitoredResource.find(monitored_resource_id)

    if period_group_id.blank?
      monitored_periods = MonitoredPeriod.all.order start_date: :asc
    else
      period_group = PeriodGroup.find(period_group_id)
      monitored_periods = period_group.monitored_periods
    end

    data = Hash.new
    chapters.each_with_index do |chapter, index|
      chapter.calculate_for(monitored_resource, monitored_periods)
      data[index] = chapter.to_h
    end

    update_attribute(:data, data)
  end
  #handle_asynchronously :generate_report_data, :queue => 'reports', :owner => Proc.new {|o| o}


  def self.build_report_data()
    # delete old report data first
    ReportData.delete_all

    monitored_periods = MonitoredPeriod.all.order(start_date: :asc)
    metrics = Report.report_metrics

    monitored_resources = MonitoredResource.all
    monitored_resources.each do |monitored_resource|
      monitored_resource.permission_groups.each do |permission_group|
        permission_group.permissions.each do |permission|
          monitored_periods.each do |monitored_period|
            monitored_period.as_days.each do |day|
              metrics.each do |metric|

                value = metric.calculate(monitored_resource.id, day, permission.id)
                if value > 0
                  ReportData.create(
                    :metric => metric.title,
                    :value => value,
                    :date => day,
                    :monitored_resource_id => monitored_resource.id,
                    :permission_group_id => permission_group.id,
                    :permission_id => permission.id
                  )
                end
              end
            end
          end
        end
      end
    end

  end

  def self.report_metrics
    return [
        Report::Metrics::NumberOfRevisions.new
    ]
  end
end
