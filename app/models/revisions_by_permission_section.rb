class RevisionsByPermissionSection < AbstractPermissionBasedSection
  def initialize_section
    @name = "Revisions"

    @metrics << RevisionsByPermission.new
  end
end