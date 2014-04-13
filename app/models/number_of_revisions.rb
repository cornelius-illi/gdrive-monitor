class NumberOfRevisions
  def name
    return "# of Revisions"
  end

  def calculate_for(monitored_resource, period, data=nil)
    return ::Revision.analyse_revisions_for(monitored_resource.id, period)
  end
end