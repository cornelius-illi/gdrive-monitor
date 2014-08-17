class Action < Activity
  def self.count(monitored_resource, monitored_period=nil)
    return if monitored_resource.blank?

    query = ["SELECT COUNT(r.id) as count FROM (SELECT revisions.* FROM resources JOIN revisions ON revisions.resource_id=resources.id WHERE monitored_resource_id=? AND batch_upload_id=0) r "]
    query.first << "LEFT JOIN (SELECT * FROM revisions WHERE batch_upload_id != 0) rr ON r.id=rr.batch_upload_id "
    query.first << "WHERE rr.id IS NULL AND r.working_session_id IS NULL AND r.collaboration IS NULL"

    query.push monitored_resource.id

    unless monitored_period.blank?
      query.first << " AND r.modified_date >= ? AND r.modified_date <= ?"
      query.push monitored_period.start_date
      query.push monitored_period.end_date
    end

    query_sanitized = ActiveRecord::Base.send(:sanitize_sql_array, query)
    result_set = ActiveRecord::Base.connection.exec_query(query_sanitized)

    return result_set.first['count']

  end
end
