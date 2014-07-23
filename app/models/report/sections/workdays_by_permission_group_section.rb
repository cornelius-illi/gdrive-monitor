class Report::Sections::WorkdaysByPermissionGroupSection < Report::Sections::AbstractPermissionGroupBasedSection
  def initialize_section
    @name = "Number of Workdays by PermissionGroup"

    @metrics << Report::Metrics::WorkdaysByPermissionGroup.new
  end
end