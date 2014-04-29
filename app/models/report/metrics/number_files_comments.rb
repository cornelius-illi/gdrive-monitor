class Report::Metrics::NumberFilesComments < Report::Metrics::AbstractMetric
  def self.title
    return "# of files with comments"
  end

  def calculate_for(monitored_resource, period, data=nil)
    query = ActiveRecord::Base.send(:sanitize_sql_array, ["SELECT COUNT(DISTINCT resources.id) AS uniq_resources FROM comments JOIN resources ON comments.resource_id=resources.id WHERE resources.monitored_resource_id=? AND (comments.created_date > ? AND comments.created_date <= ?)", monitored_resource.id, period.start_date, period.end_date])
    result = ActiveRecord::Base.connection.exec_query(query)
    result.first['uniq_resources']
  end
end