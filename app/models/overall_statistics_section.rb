class OverallStatisticsSection < AbstractSection

  def initialize_section
    @name = ""

    @metrics << NumberDaysPeriod.new
    @metrics << NumberOfFilesCreated.new
    @metrics << NumberOfFilesModified.new
    @metrics << NumberAverageFilesCreated.new
    @metrics << NumberOfGoogleFilesModified.new
    @metrics << RatioGoogleModifiedFiles.new
    @metrics << NumberOfRevisions.new
    @metrics << NumberAverageRevisions.new
    @metrics << RatioRevisionsModifiedFiles.new
  end
end