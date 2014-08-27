class Report::Sections::AbstractPermissionBasedSection < Report::Sections::AbstractSection
  def calculate_for(monitored_resource, monitored_periods)
    @metrics.each do |metric|
      monitored_resource.permission_groups.each do |perm_group|
        count_perm_group = 0
        @data[perm_group.name] = Hash.new

        # initialize all periods for period-group with 0
        monitored_periods.each do |period|
          @data[perm_group.name][period.id] = 0
        end

        perm_group.permissions.each do |permission|
          @data[permission.unique_title] = Hash.new

          monitored_periods.each do |period|
            value_permission_period = metric.calculate_for(monitored_resource, period, permission, @data)
            @data[permission.unique_title][period.id] = value_permission_period

            # add to permission group for totals
            @data[perm_group.name][period.id] += value_permission_period
          end

        end

      end
    end
  end
end