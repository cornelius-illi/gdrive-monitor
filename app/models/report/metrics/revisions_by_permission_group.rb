class Report::Metrics::RevisionsByPermissionGroup < Report::Metrics::AbstractPermissionGroupBasedMetric
  def self.title
    return "# of revisions"
  end

  def calculate_for(monitored_resource, period, permission_group)
    return Revision.count_revisions_by_permissiongroup(monitored_resource.id, period, permission_group)
  end
end