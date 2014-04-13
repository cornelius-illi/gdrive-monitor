class Report < ActiveRecord::Base
  belongs_to  :monitored_resource
  belongs_to  :monitored_period
  
  serialize :data, Hash

  # *** DELAYED TASKS - START
  def generate_report_data
    return if monitored_resource_id.blank?

    # initialize here
    data = Hash.new

    data_nbr_of_files()
    data_nbr_of_revisions()
    nbr_revisions_per_user()

    # http://www.davidverhasselt.com/set-attributes-in-activerecord/
    save!
  end
  handle_asynchronously :generate_report_data, :queue => 'reports', :owner => Proc.new {|o| o}
  # *** DELAYED TASKS - STOP

  private
  def data_nbr_of_files
    unless monitored_period_id.blank?
      monitored_period = MonitoredPeriod.find(monitored_period_id)

      nbr_files_created = Resource.analyse_new_resources_for(monitored_resource_id, monitored_period)
      nbr_files_modified = Resource.analyse_modified_resources_for(monitored_resource_id, monitored_period)
      data['numbers_table'] ||= Hash.new
      data['numbers_table']['nbr_files_created']               = nbr_files_created
      data['numbers_table']['avg_files_created']               = (nbr_files_created.to_f/monitored_period.days).round(2)
      data['numbers_table']['nbr_files_modified']               = nbr_files_modified
      data['numbers_table']['avg_files_modified']               = (nbr_files_modified.to_f/monitored_period.days).round(2)
      data['numbers_table']['nbr_google_files_modified']       = Resource.analyse_modified_resources_for(monitored_resource_id, monitored_period, true)
      data['numbers_table']['ratio_google_vs_modified_files']  = (data['numbers_table']['nbr_files_modified'].to_i == 0) ? 0 : (data['numbers_table']['nbr_google_files_modified']/ data['numbers_table']['nbr_files_modified'].to_f).round(3)
    end
  end

  def data_nbr_of_revisions
    unless monitored_period_id.blank?
      monitored_period = MonitoredPeriod.find(monitored_period_id)

      nbr_of_revisions = Revision.analyse_revisions_for(monitored_resource_id, monitored_period)
      data['numbers_table'] ||= Hash.new
      data['numbers_table']['nbr_of_revisions'] = nbr_of_revisions
      data['numbers_table']['avg_of_revisions']  = (nbr_of_revisions.to_f/monitored_period.days).round(2)
      data['numbers_table']['ratio_revisions_vs_files_modified'] = (data['numbers_table']['nbr_files_modified'].to_i == 0) ? 0 : (nbr_of_revisions.to_f/ data['numbers_table']['nbr_files_modified']).round(3)
    end
  end

  def nbr_revisions_per_user
    unless monitored_period_id.blank?
      monitored_period = MonitoredPeriod.find(monitored_period_id)
      monitored_resource = MonitoredResource.find(monitored_resource_id)

      data['users_table'] = Hash.new

      monitored_resource.permission_groups.each do |perm_group|
        data['users_table'][perm_group.name] = Hash.new
        perm_group.permissions.each do |permission|
          perm_key = "#{permission.id}: #{permission.title}"
          data['users_table'][perm_group.name][perm_key] = Hash.new
          nbr_revisions_permission = Revision.analyse_revisions_for(monitored_resource_id, monitored_period, permission.id)
          data['users_table'][perm_group.name][perm_key]['nbr_revisions_permission'] = nbr_revisions_permission
        end # permission
      end # perm_group
    end # resource
  end

end
