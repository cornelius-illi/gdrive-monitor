class Report::Chapters::OverallStatisticsChapter < Report::Chapters::AbstractChapter
 def initialize_chapter
  @name = 'Overall Statistics'
  @sections << Report::Sections::OverallStatisticsSection.new
 end
end