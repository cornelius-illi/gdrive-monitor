class Report::Metrics::WorkdaysByPermissionGroup < Report::Metrics::AbstractPermissionGroupBasedMetric
  def self.title
    return "# of working days"
  end

  def calculate_for(monitored_resource, period, permission_group)
    return Revision.count_workdays_for(monitored_resource.id, period, permission_group)
  end
end