class Report::Sections::WorkdaysRankedByPermissionGroupSection < Report::Sections::AbstractPermissionGroupBasedSection
  def initialize_section
    @name = "Workdays by permission-group"

    @metrics << Report::Metrics::WorkdaysRankedByPermissionGroup.new
  end
end