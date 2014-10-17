class Report::Metrics::NumberOfReplies < Report::Metrics::AbstractMetric
  def self.title
    return "# of replies"
  end

  def calculate_for(monitored_resource, period, data=nil)
    q = "SELECT COUNT(comments.id) AS comments FROM comments JOIN resources ON comments.resource_id=resources.id WHERE comments.comment_id IS NOT NULL AND resources.monitored_resource_id=? AND (comments.created_date > ? AND comments.created_date <= ?) "
    query = ActiveRecord::Base.send(:sanitize_sql_array, [q, monitored_resource.id, period.start_date, period.end_date])
    result = ActiveRecord::Base.connection.exec_query(query)
    result.first['comments']
  end
end