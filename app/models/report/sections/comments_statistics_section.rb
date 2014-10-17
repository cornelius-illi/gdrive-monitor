class Report::Sections::CommentsStatisticsSection < Report::Sections::AbstractSection
  def initialize_section
    @name = "Comments statistics"

    @metrics << Report::Metrics::NumberFilesComments.new
    @metrics << Report::Metrics::NumberComments.new
    @metrics << Report::Metrics::NumberOfReplies.new
    @metrics << Report::Metrics::NumberUnresolvedComments.new
    #@metrics << Report::Metrics::RatioUnresolvedTotalComments.new

  end
end