class BatchUpload < Activity

  BATCH_UPLOAD_THRESHOLD = 10.seconds.freeze

  def self.create_all_batch_uploads()
    # initially reset
    Revision.update_all batch_upload_id: 'NULL'
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
        query = ["SELECT revisions.id, revisions.resource_id, revisions.modified_date FROM resources JOIN revisions ON revisions.resource_id=resources.id"]
        query.first << " WHERE resources.monitored_resource_id=? AND revisions.modified_date >= ? AND revisions.modified_date <= ?"
        query.first << " ORDER BY revisions.modified_date DESC"
        query.push monitored_resource.id
        query.push period.start_date
        query.push period.end_date

        query_sanitized = ActiveRecord::Base.send(:sanitize_sql_array, query)
        result_set = ActiveRecord::Base.connection.exec_query(query_sanitized)

        unless result_set.blank?
          master_id = result_set.first['id']
          master_modified_date = result_set.first['modified_date']

          result_set.each do |row|
            modified_date = row['modified_date']
            if master_id != row['id'] && (modified_date + BATCH_UPLOAD_THRESHOLD) >= master_modified_date
              Revision.find(row['id']).update_attributes(:batch_upload_id => master_id)
            else
              master_id = row['id'] # new master is the next one
            end

            master_modified_date = modified_date # sliding window, changes everytime
          end
        end

      end
    end
  end

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


