class Report::Metrics::FilesCreatedByPermission < Report::Metrics::AbstractPermissionBasedMetric

  def calculate_for(monitored_resource, period, permission, data=nil)
    return Resource
      .where(:monitored_resource_id => monitored_resource.id)
      .where(:permission_id => permission.id)
      .where('resources.created_date > "%s" AND resources.created_date <= "%s"', period.start_date, period.end_date)
      .count()
  end
end