class Report::Metrics::NumberOfImages < Report::Metrics::AbstractMetric
  def self.title
    return "# of Images Uploaded"
  end

  def calculate_for(monitored_resource, period, data=nil)
    sql = 'SELECT COUNT(revisions.id) AS images FROM revisions JOIN resources ON revisions.resource_id=resources.id
      WHERE resources.mime_type="image/jpeg" AND resources.monitored_resource_id=?
      AND revisions.modified_date > ? AND revisions.modified_date <= ?;'
    query  = ActiveRecord::Base.send(:sanitize_sql_array, [sql, monitored_resource.id, period.start_date, period.end_date])
    images_in_period = ActiveRecord::Base.connection.execute(query)
    return images_in_period[0]['images']
  end
end