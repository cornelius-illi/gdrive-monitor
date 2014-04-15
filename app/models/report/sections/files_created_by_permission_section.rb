class Report::Sections::FilesCreatedByPermissionSection < Report::Sections::AbstractPermissionBasedSection
  def initialize_section
    @name = "Files Created/ permission"

    @metrics << Report::Metrics::FilesCreatedByPermission.new
  end
end