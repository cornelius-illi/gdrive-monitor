class OverallStatisticsChapter < AbstractChapter
 def initialize_chapter
  @name = 'Overall Statistics'
  @sections << OverallStatisticsSection.new
 end
end