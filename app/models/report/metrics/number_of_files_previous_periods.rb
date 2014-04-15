class Report::Metrics::NumberOfFilesPreviousPeriods < Report::Metrics::AbstractMetric
  def self.title
    return "# modified files from previous periods"
  end

  def calculate_for(monitored_resource, period, data=nil)
    query = ActiveRecord::Base.send(:sanitize_sql_array, ["SELECT COUNT(resources.id) as resources FROM resources WHERE resources.monitored_resource_id=? AND resources.created_date < ? AND (resources.modified_date > ? AND resources.modified_date <= ?) ", monitored_resource.id, period.start_date, period.start_date, period.end_date])
    result = ActiveRecord::Base.connection.execute(query)
    result.first['resources']
  end
end