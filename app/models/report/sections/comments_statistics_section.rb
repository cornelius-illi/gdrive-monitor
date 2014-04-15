class Report::Sections::CommentsStatisticsSection < Report::Sections::AbstractSection
  def initialize_section
    @name = "Comments statistics"

    @metrics << Report::Metrics::NumberFilesComments.new
    @metrics << Report::Metrics::NumberTotalComments.new
    @metrics << Report::Metrics::NumberComments.new
    @metrics << Report::Metrics::NumberResolvedComments.new
    @metrics << Report::Metrics::RatioResolvedTotalComments.new

  end
end