class Report::Metrics::NumberParallelActivities < Report::Metrics::AbstractMetric
  def self.title
    return "# collaborative sessions (GOOGLE)"
  end

  def calculate_for(monitored_resource, period, data=nil)
    # for all resources in monitored_resource that have been modified within current period and that are GOOGLE_FILE_TYPE

    nbr_parallel_activities = 0

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

      nbr_parallel_activities += revisions_with_parallel_activity.rows.length
    end

    return nbr_parallel_activities
  end

end