class Report::Metrics::RevisionsByWorksdaysAndPermissionGroup < Report::Metrics::AbstractPermissionGroupBasedMetric
  def calculate_for(monitored_resource, period, permission_group)
    return Revision.count_revisions_by_weekday(monitored_resource.id, period, permission_group)
  end
end