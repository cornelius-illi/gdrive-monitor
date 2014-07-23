class Report::Chapters::PermissionGroupBasedChapter < Report::Chapters::AbstractChapter
  def initialize_chapter
    @name = 'PermissionGroup-based Statistics'

    @sections << Report::Sections::WorkdaysByPermissionGroupSection.new
    @sections << Report::Sections::RevisionsByWorksdaysAndPermissionGroupSection.new
  end
end