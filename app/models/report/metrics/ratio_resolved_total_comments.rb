class Report::Metrics::RatioResolvedTotalComments < Report::Metrics::AbstractMetric
  def self.title
    "Ratio resolved vs. total comments"
  end

  def calculate_for(monitored_resource, period, data=nil)
    nbr_comments = data[Report::Metrics::NumberTotalComments.title][period.id]
    nbr_resolved_comments = data[Report::Metrics::NumberResolvedComments.title][period.id]
    return nbr_comments.to_i == 0 ? 0 : (nbr_resolved_comments/nbr_comments.to_f).round(2)
  end
end