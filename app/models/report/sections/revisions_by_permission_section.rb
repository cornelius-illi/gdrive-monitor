class Report::Sections::RevisionsByPermissionSection < Report::Sections::AbstractPermissionBasedSection
  def initialize_section
    @name = "Revisions/ permission"

    @metrics << Report::Metrics::RevisionsByPermission.new
  end
end