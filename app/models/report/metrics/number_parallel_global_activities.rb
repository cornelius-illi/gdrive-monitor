class Report::Metrics::NumberParallelGlobalActivities < Report::Metrics::AbstractMetric
  def self.title
    return "# global collaborative sessions (GOOGLE)"
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
      sql = 'SELECT a.id,a.permission_id, GROUP_CONCAT(DISTINCT b.permission_id) as permissions
        FROM revisions a JOIN revisions b ON b.collaboration_id=a.id
        WHERE b.resource_id=? AND b.modified_date > ? AND b.modified_date <= ? GROUP BY a.id;'
      query = ActiveRecord::Base.send(:sanitize_sql_array, [sql, resource.id, period.start_date, period.end_date])
      revisions_with_parallel_activity = ActiveRecord::Base.connection.execute(query)

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