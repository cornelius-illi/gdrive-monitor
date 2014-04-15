class Report::Metrics::NumberComments < Report::Metrics::AbstractMetric
  def self.title
    return "# of comments with reply"
  end

  def calculate_for(monitored_resource, period, data=nil)
    query = ActiveRecord::Base.send(:sanitize_sql_array, ["SELECT COUNT(DISTINCT a.id) AS comments FROM comments a JOIN comments b ON a.id=b.comment_id JOIN resources ON a.resource_id = resources.id WHERE resources.monitored_resource_id=? AND (b.created_date > ? AND b.created_date <= ?) ", monitored_resource.id, period.start_date, period.end_date])
    result = ActiveRecord::Base.connection.execute(query)
    result.first['comments']
  end
end