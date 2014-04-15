class Report::Sections::CollaborationStatisticsSection < Report::Sections::AbstractSection
  def initialize_section
    @name = "Collaboration statistics"

    @metrics << Report::Metrics::NumberCollaboratedFiles.new
    @metrics << Report::Metrics::NumberGloballyCollaboratedFiles.new
    @metrics << Report::Metrics::NumberParallelActivities.new
    @metrics << Report::Metrics::NumberParallelGlobalActivities.new
  end
end