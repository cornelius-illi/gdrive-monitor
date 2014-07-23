class Report::Metrics::NumberGloballyCollaboratedFiles < Report::Metrics::AbstractMetric
  def self.title
    return "# of globally collab. files"
  end

  def calculate_for(monitored_resource, period, data=nil)
    nbr_globally_collaborated_resources = 0
    query = query = ActiveRecord::Base.send(:sanitize_sql_array, ["SELECT revisions.resource_id, GROUP_CONCAT(DISTINCT revisions.permission_id) as permissions FROM revisions JOIN resources ON revisions.resource_id=resources.id WHERE resources.monitored_resource_id=? AND (resources.modified_date > ? AND resources.modified_date <= ?) GROUP BY revisions.resource_id HAVING COUNT(DISTINCT revisions.permission_id) > 1", monitored_resource.id, period.start_date, period.end_date])
    resources_with_collaboration = ActiveRecord::Base.connection.exec_query(query)

    # only works for groups n=2
    group = PermissionGroup.where(:monitored_resource_id => monitored_resource.id).first
    perm_group_ids = Array.new
    group.permissions.each do |perm|
      perm_group_ids << perm.id
    end

    resources_with_collaboration.each do |resource|
      permission_array = resource['permissions'].split(',').map(&:to_i)
      intersection = permission_array & perm_group_ids
      # two cases are relevant: all match, none matches -> one group did all the work
      if !((intersection).length.eql?(permission_array.length) || intersection.length.eql?(0))
        nbr_globally_collaborated_resources += 1
      end
    end

    return nbr_globally_collaborated_resources
  end
end