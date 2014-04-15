class Report::Metrics::NumberTotalComments < Report::Metrics::AbstractMetric
  def self.title
    return "# of total comments"
  end

  def calculate_for(monitored_resource, period, data=nil)
    query = ActiveRecord::Base.send(:sanitize_sql_array, ["SELECT COUNT(comments.id) AS comments FROM comments JOIN resources ON comments.resource_id=resources.id WHERE resources.monitored_resource_id=? AND (comments.created_date > ? AND comments.created_date <= ?) ", monitored_resource.id, period.start_date, period.end_date])
    result = ActiveRecord::Base.connection.execute(query)
    result.first['comments']
  end
end