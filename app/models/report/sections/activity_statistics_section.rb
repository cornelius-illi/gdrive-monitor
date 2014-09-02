class Report::Sections::ActivityStatisticsSection < Report::Sections::AbstractSection
  def initialize_section
    @name = "Activity statistics"

    @metrics << Report::Metrics::NumberWorkingDays.new
    @metrics << Report::Metrics::NumberActions.new
    @metrics << Report::Metrics::NumberBatchUploads.new
    @metrics << Report::Metrics::NumberWorkingSessions.new
    @metrics << Report::Metrics::NumberCollaborativeSessions.new
    @metrics << Report::Metrics::NumberGlobalCollaborativeSessions.new
    @metrics << Report::Metrics::SumActivities.new
    @metrics << Report::Metrics::RatioActivitiesWorkdays.new
    @metrics << Report::Metrics::SumGlobalCollaborationActivities.new
    @metrics << Report::Metrics::SumGlobalCollaborationActivitiesGroups.new
  end
end