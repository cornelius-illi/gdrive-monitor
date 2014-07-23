class Report::Metrics::NumberParallelGlobalActivities < Report::Metrics::AbstractMetric
  def self.title
    return "# global collab. sessions (GD)"
  end

  def calculate_for(monitored_resource, period, data=nil)
    # for all resources in monitored_resource that have been modified within current period and that are GOOGLE_FILE_TYPE

    nbr_global_parallel_activities = 0

    # only works for groups n=2
    group = PermissionGroup.where(:monitored_resource_id => monitored_resource.id).first
    perm_group_ids = Array.new
    group.permissions.each do |perm|
      perm_group_ids << perm.id
    end

    resources = Resource.google_resources_for_period(monitored_resource,period)
    resources.each do |resource|
      sql = 'SELECT collaborations.collaboration_id, revisions.permission_id as permission_id,
          GROUP_CONCAT(DISTINCT collaborations.permission_id) as permissions
        FROM collaborations
        JOIN revisions ON collaborations.collaboration_id=revisions.id
        WHERE revisions.resource_id=? AND collaborations.threshold=?
          AND revisions.permission_id != collaborations.permission_id
          AND revisions.modified_date > ? AND revisions.modified_date <= ?
        GROUP BY collaborations.collaboration_id ORDER BY revisions.resource_id;'
      query = ActiveRecord::Base.send(:sanitize_sql_array, [
          sql, resource.id, Collaboration::STANDARD_COLLABORATION_THRESHOLD.to_i,
          period.start_date, period.end_date]
      )
      revisions_with_parallel_activity = ActiveRecord::Base.connection.exec_query(query)

      revisions_with_parallel_activity.each do |revision|
        permission_array = [ revision['permission_id'], revision['permissions'].split(',').map(&:to_i) ]
        intersection = permission_array & perm_group_ids
        # two cases are relevant: all match, none matches -> one group did all the work
        if !((intersection).length.eql?(permission_array.length) || intersection.length.eql?(0))
          nbr_global_parallel_activities += 1
        end
      end
    end

    return nbr_global_parallel_activities
  end
end