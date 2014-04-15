class Report::Sections::OverallStatisticsSection < Report::Sections::AbstractSection

  def initialize_section
    @name = ""

    @metrics << Report::Metrics::NumberDaysPeriod.new
    @metrics << Report::Metrics::NumberFilesTotal.new
    @metrics << Report::Metrics::NumberOfFilesCreated.new
    @metrics << Report::Metrics::NumberOfFilesModified.new
    @metrics << Report::Metrics::NumberOfFilesPreviousPeriods.new
    @metrics << Report::Metrics::NumberAverageFilesCreated.new
    @metrics << Report::Metrics::NumberOfGoogleFilesModified.new
    @metrics << Report::Metrics::RatioGoogleModifiedFiles.new
    @metrics << Report::Metrics::NumberOfRevisions.new
    @metrics << Report::Metrics::NumberAverageRevisions.new
    @metrics << Report::Metrics::RatioRevisionsModifiedFiles.new
    @metrics << Report::Metrics::NumberFilesComments.new
    @metrics << Report::Metrics::NumberTotalComments.new
    @metrics << Report::Metrics::NumberComments.new
    @metrics << Report::Metrics::NumberResolvedComments.new
    @metrics << Report::Metrics::RatioResolvedTotalComments.new

  end
end