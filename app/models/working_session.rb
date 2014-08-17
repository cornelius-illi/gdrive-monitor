class WorkingSession < Activity
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

SELECT revisions.id
FROM revisions LEFT JOIN (SELECT * FROM collaborations WHERE collaborations.threshold=960) AS c ON c.revision_id=revisions.id
JOIN resources ON revisions.resource_id=resources.id
WHERE resources.monitored_resource_id=4 AND (c.id IS NULL) AND revisions.modified_date >= '2014-01-31 00:00:00' AND revisions.modified_date <= '2014-02-13 23:59:59'

Action:
    all revisions that have no match revisions.id = collaborations.collaboration_id WHERE threshold=960
    JOIN collaborations collaborations.collaboration_id = revisions.id

WorkingSession:
    COUNT(DISTINCT permissions = 1)

Collaboration:
    COUNT(DISTINCT permissions = 2)
