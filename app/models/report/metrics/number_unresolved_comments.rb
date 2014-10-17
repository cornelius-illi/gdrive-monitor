class Report::Metrics::NumberUnresolvedComments < Report::Metrics::AbstractMetric
  def self.title
    return "# unresolved comments"
  end

  def calculate_for(monitored_resource, period, data=nil)
    q = "SELECT COUNT(comments.id) AS comments FROM comments JOIN resources ON comments.resource_id=resources.id WHERE comments.status='open' AND resources.monitored_resource_id=? AND (comments.created_date > ? AND comments.created_date <= ?) "
    query = ActiveRecord::Base.send(:sanitize_sql_array, [q, monitored_resource.id, period.start_date, period.end_date])
    result = ActiveRecord::Base.connection.exec_query(query)
    result.first['comments']
  end
end