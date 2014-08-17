class Report::Metrics::NumberCollaboratedFiles < Report::Metrics::AbstractMetric
  def self.title
    return "# of collab. files"
  end

  def calculate_for(monitored_resource, period, data=nil)
    # this does not check if work has done synchronously or aynchronously, just that collaboration has taken place
    query = ActiveRecord::Base.send(:sanitize_sql_array, ["SELECT revisions.resource_id, COUNT(DISTINCT revisions.permission_id) FROM revisions JOIN resources ON revisions.resource_id=resources.id WHERE resources.monitored_resource_id=? AND (resources.modified_date > ? AND resources.modified_date <= ?) GROUP BY revisions.resource_id HAVING COUNT(DISTINCT revisions.permission_id) > 1", monitored_resource.id, period.start_date, period.end_date])
    result = ActiveRecord::Base.connection.exec_query(query)
    return result.rows.length
  end
end

