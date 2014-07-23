class Report::Chapters::OverallStatisticsChapter < Report::Chapters::AbstractChapter
 def initialize_chapter
  @name = 'Overall Statistics'
  @sections << Report::Sections::FilesStatisticsSection.new
  #@sections << Report::Sections::CollaborationStatisticsSection.new
  @sections << Report::Sections::CommentsStatisticsSection.new
 end
end