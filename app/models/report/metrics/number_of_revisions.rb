class Report::Metrics::NumberOfRevisions < Report::Metrics::AbstractMetric
  def self.title
    return "# of Revisions"
  end

  def calculate_for(monitored_resource, period, data=nil)
    return ::Revision.analyse_revisions_for(monitored_resource.id, period)
  end

  def calculate(monitored_resource_id, day, permission_id)
    period = Hash.new
    period['start_date'] = "#{day} 00:00:00"
    period['end_date'] = "#{day} 23:59:59"

    return ::Revision
      .count_for(monitored_resource_id, period, permission_id)
  end
end