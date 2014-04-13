class PermissionBasedChapter < AbstractChapter
  def initialize_chapter
    @name = 'Permission-based Statistics'
    @sections << RevisionsByPermissionSection.new
  end
end