class Action < Activity
  def self.count(monitored_resource, monitored_period=nil, resource_ids=nil)
    return if monitored_resource.blank?

    batch_uploads_query = ["SELECT DISTINCT r.batch_upload_id FROM revisions r JOIN resources rr ON rr.id=r.resource_id WHERE rr.monitored_resource_id=? AND r.modified_date >= ? AND r.modified_date <= ? AND r.batch_upload_id != 0;"]
    batch_uploads_query.push monitored_resource.id
    batch_uploads_query.push monitored_period.start_date
    batch_uploads_query.push monitored_period.end_date
    batch_uploads_query_sanitized = ActiveRecord::Base.send(:sanitize_sql_array, batch_uploads_query)
    batch_uploads = ActiveRecord::Base.connection.exec_query(batch_uploads_query_sanitized)
    batch_upload_ids = batch_uploads.map {|n| n['batch_upload_id']}


    query = ["SELECT COUNT(rr.id) as count FROM resources r JOIN revisions rr ON rr.resource_id=r.id WHERE r.monitored_resource_id=? AND rr.batch_upload_id=0 AND rr.working_session_id IS NULL AND rr.collaboration IS NULL "]
    query.push monitored_resource.id

    if !resource_ids.blank? && resource_ids.is_a?(Array)
      query.first << " AND r.id IN (#{resource_ids.join(",")}) "
    end

    if !batch_upload_ids.blank? && batch_upload_ids.is_a?(Array)
      query.first << " AND rr.id NOT IN (#{batch_upload_ids.join(",")}) "
    end

    unless monitored_period.blank?
      query.first << " AND rr.modified_date >= ? AND rr.modified_date <= ?"
      query.push monitored_period.start_date
      query.push monitored_period.end_date
    end

    query_sanitized = ActiveRecord::Base.send(:sanitize_sql_array, query)
    result_set = ActiveRecord::Base.connection.exec_query(query_sanitized)

    return result_set.first['count']

  end
end
