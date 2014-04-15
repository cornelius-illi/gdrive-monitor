class Report::Chapters::PermissionBasedChapter < Report::Chapters::AbstractChapter
  def initialize_chapter
    @name = 'Permission-based Statistics'

    @sections << Report::Sections::RevisionsByPermissionSection.new
    @sections << Report::Sections::FilesCreatedByPermissionSection.new
  end
end