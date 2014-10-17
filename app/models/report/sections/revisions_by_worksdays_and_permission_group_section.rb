class Report::Sections::RevisionsByWorksdaysAndPermissionGroupSection < Report::Sections::AbstractPermissionGroupBasedSection
  def initialize_section
    @name = "Revisions by permission-groups"
    @metrics << Report::Metrics::RevisionsByPermissionGroup.new
    #@metrics << Report::Metrics::RevisionsByWorksdaysAndPermissionGroup.new
  end
end