class Report::Chapters::PermissionGroupBasedChapter < Report::Chapters::AbstractChapter
  def initialize_chapter
    @name = 'PermissionGroup-based Statistics'

    @sections << Report::Sections::WorkdaysRankedByPermissionGroupSection.new
  end
end