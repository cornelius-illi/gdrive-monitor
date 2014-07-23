class Report::Sections::RevisionsByWorksdaysAndPermissionGroupSection < Report::Sections::AbstractPermissionGroupBasedSection
  def initialize_section
    @name = "Revisions by weekdays and permission-groups"

    @metrics << Report::Metrics::RevisionsByWorksdaysAndPermissionGroup.new
  end
end