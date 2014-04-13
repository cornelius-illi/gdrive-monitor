class RevisionsByPermission < AbstractPermissionBasedMetric

  def calculate_for(monitored_resource, period, permission, data=nil)
    return Revision.analyse_revisions_for(monitored_resource.id, period, permission.id)
  end
end