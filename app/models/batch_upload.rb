class BatchUpload < Activity

  BATCH_UPLOAD_THRESHOLD = 10.seconds.freeze

  def self.create_all_batch_uploads()
    # initially reset
    Revision.update_all("batch_upload_id = 0")
    #ActiveRecord::Base.connection.exec_query("UPDATE revisions SET revisions.batch_upload_id = NULL")

    # fetch and iterate all
    MonitoredResource.all.each do |monitored_resource|
      BatchUpload.create_batch_uploads(monitored_resource)
    end

    return true
  end

  def self.create_batch_uploads(monitored_resource)
    # ALGORITHM: for every permission,
    # and every period
    #   get all the revisions within the given period ORDER BY modified_date DESC
    #     if the previous revision is within a time-window of 10 seconds set batch_upload_id on that previous to the current
    #     proceed until nothing else is found

    monitored_periods = MonitoredPeriod.all

    monitored_resource.permissions.each do |permission|
      monitored_periods.each do |period|
        # get all revisions of Resource for a MonitoredResource for a given period and order them by modified_date
        # pre-condition: working-sessions have to be aggregated first, because all revisions that belong to one are excluded
        query = ["SELECT revisions.id, revisions.resource_id, revisions.modified_date FROM resources JOIN revisions ON revisions.resource_id=resources.id"]
        query.first << " WHERE resources.monitored_resource_id=? AND revisions.permission_id=? AND revisions.modified_date >= ? AND revisions.modified_date <= ? AND working_session_id IS NULL and collaboration IS NULL"
        query.first << " ORDER BY revisions.modified_date DESC"
        query.push monitored_resource.id
        query.push permission.id
        query.push period.start_date
        query.push period.end_date

        query_sanitized = ActiveRecord::Base.send(:sanitize_sql_array, query)
        result_set = ActiveRecord::Base.connection.exec_query(query_sanitized)

        unless result_set.blank?
          master_id = result_set.first['id']
          master_modified_date = result_set.first['modified_date']
          master_resource_id = result_set.first['resource_id']

          result_set.each do |row|
            modified_date = row['modified_date']

            if (master_id != row['id']) && ((modified_date + BATCH_UPLOAD_THRESHOLD) >= master_modified_date) && master_resource_id != row['resource_id']
              Revision.find(row['id']).update(:batch_upload_id => master_id)
            else
              master_id = row['id'] # new master is the next one
            end

            master_modified_date = modified_date # sliding window, changes everytime
          end
        end

      end
    end
  end

  def self.count(monitored_resource, monitored_period=nil)
    return if monitored_resource.blank?

    query = ["SELECT COUNT(*) as count FROM (SELECT COUNT(r.id) as count FROM (SELECT revisions.* FROM resources JOIN revisions ON revisions.resource_id=resources.id WHERE monitored_resource_id=? AND batch_upload_id=0) r "]
    query.first << "JOIN (SELECT * FROM revisions WHERE batch_upload_id != 0) rr ON r.id=rr.batch_upload_id "
    query.first << "WHERE r.working_session_id IS NULL AND r.collaboration IS NULL "

    query.push monitored_resource.id

    unless monitored_period.blank?
      query.first << "AND r.modified_date >= ? AND r.modified_date <= ?"
      query.push monitored_period.start_date
      query.push monitored_period.end_date
    end

    query.first << " GROUP BY r.id) actions"

    query_sanitized = ActiveRecord::Base.send(:sanitize_sql_array, query)
    result_set = ActiveRecord::Base.connection.exec_query(query_sanitized)

    return result_set.first['count']

  end
end