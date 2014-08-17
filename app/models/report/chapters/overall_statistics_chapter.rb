class Report::Chapters::OverallStatisticsChapter < Report::Chapters::AbstractChapter
 def initialize_chapter
  @name = 'Overall Statistics'
  @sections << Report::Sections::FilesStatisticsSection.new
  @sections << Report::Sections::ActivityStatisticsSection.new
  @sections << Report::Sections::CommentsStatisticsSection.new
 end
end