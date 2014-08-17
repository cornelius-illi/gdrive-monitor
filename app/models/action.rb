class Action < Activity

  def count(monitored_resource, monitored_period=nil)
    return if monitored_resource.blank?

    where = ["WHERE resources.monitored_resource_id=?"]
    where.push monitored_resource.id

    unless monitored_resource.blank?
      where.first << "revisions.modified_date >= ? AND revisions.modified_date <= ?"
      where.push monitored_period.start_date
      where.push monitored_period.end_date
    end

    where_sanitized = ActiveRecord::Base.send(:sanitize_sql_array, where)


    query = "SELECT COUNT( DISTINCT revisions.batch_upload_id) as count FROM resources JOIN revisions ON revisions.resource_id=resources.id #{where_sanitized}"
    result_set = ActiveRecord::Base.connection.exec_query(query)

    return result_set['count']
  end
end