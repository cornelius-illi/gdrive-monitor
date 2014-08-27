class Report::Sections::AbstractPermissionGroupBasedSection < Report::Sections::AbstractSection
  def calculate_for(monitored_resource, monitored_periods)
    @metrics.each do |metric|
      monitored_resource.permission_groups.each do |perm_group|
        @data[perm_group.name] = Hash.new

        monitored_periods.each do |period|
          @data[perm_group.name][period.id] = metric.calculate_for(monitored_resource, period, perm_group)
        end
      end
    end
  end
end