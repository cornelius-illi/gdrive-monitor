class Report::Metrics::NumberParallelActivities < Report::Metrics::AbstractMetric
  def self.title
    return "# collaborative sessions (GOOGLE)"
  end

  def calculate_for(monitored_resource, period, data=nil)
    # for all resources in monitored_resource that have been modified within current period and that are GOOGLE_FILE_TYPE

    nbr_parallel_activities = 0

    resources = Resource.google_resources_for_period(monitored_resource,period)
    resources.each do |resource|
      # @TODO: this does not include the one revision that is the master ...
      sql = 'SELECT a.id,a.permission_id, GROUP_CONCAT(DISTINCT b.permission_id) as permissions
        FROM revisions a JOIN revisions b ON b.collaboration_id=a.id
        WHERE b.resource_id=? AND b.permission_id != a.permission_id AND b.modified_date > ? AND b.modified_date <= ? GROUP BY a.id;'
      query = ActiveRecord::Base.send(:sanitize_sql_array, [sql, resource.id, period.start_date, period.end_date])
      revisions_with_parallel_activity = ActiveRecord::Base.connection.execute(query)

      nbr_parallel_activities += revisions_with_parallel_activity.length
    end

    return nbr_parallel_activities
  end

end