class Report::Sections::CollaborationStatisticsSection < Report::Sections::AbstractSection
  def initialize_section
    @name = "Collaboration statistics"

    @metrics << Report::Metrics::NumberWorkingDays.new
    @metrics << Report::Metrics::NumberCollaboratedFiles.new
    @metrics << Report::Metrics::RatioCollaboratedFilesWorkdays.new
    @metrics << Report::Metrics::NumberGloballyCollaboratedFiles.new
    @metrics << Report::Metrics::RatioGloballyCollaboratedFilesWorkdays.new
    @metrics << Report::Metrics::NumberCollaborativeSessions.new
    @metrics << Report::Metrics::NumberParallelGlobalActivities.new
  end
end