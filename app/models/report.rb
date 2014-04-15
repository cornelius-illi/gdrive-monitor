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

    monitored_resource ||= MonitoredResource.find(monitored_resource_id)
    period_group ||= PeriodGroup.find(period_group_id)

    data = Hash.new
    chapters.each_with_index do |chapter, index|
      chapter.calculate_for(monitored_resource, period_group)
      data[index] = chapter.to_h
    end

    update_attribute(:data, data)
  end
  #handle_asynchronously :generate_report_data, :queue => 'reports', :owner => Proc.new {|o| o}
end
