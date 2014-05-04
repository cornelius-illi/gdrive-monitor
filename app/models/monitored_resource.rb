class MonitoredResource < ActiveRecord::Base
  has_many  :resources, -> { where.not(mime_type: GOOGLE_FOLDER_TYPE) }, :dependent => :delete_all
  has_many  :permissions, :dependent => :delete_all
  has_many  :permission_groups, :dependent => :delete_all
  has_many  :reports, :dependent => :delete_all
  has_and_belongs_to_many :monitored_periods
  has_many :jobs, :class_name => "::Delayed::Job", :as => :owner

  GOOGLE_FOLDER_TYPE = 'application/vnd.google-apps.folder'.freeze
  GOOGLE_FILE_TYPES = %w(
    application/vnd.google-apps.drawing
    application/vnd.google-apps.document
    application/vnd.google-apps.spreadsheet
    application/vnd.google-apps.presentation
  ).freeze

  #def self.jobs
    # to address the STI scenario we use base_class.name.
    # downside: you have to write extra code to filter STI class specific instance.
    #Delayed::Job.find_all_by_owner_type(self.base_class.name)
  #end

  def report_for_period_group(period_group)
    reports.each do |report|
      return report if report.period_group_id.eql?(period_group.id)
    end
    return nil
  end

  def resources_analysed(page=0,per_page=10, filters=[], sort_column='resources.modified_date', sort_direction='asc')
      offset = page*per_page

      where_sql = create_where_statement filters

      query = "SELECT resources.id, resources.title, resources.created_date, resources.modified_date, resources.mime_type, resources.icon_link, COUNT(DISTINCT revisions.id) as revisions,
      COUNT(DISTINCT revisions.permission_id) as permissions, COUNT(DISTINCT permission_groups_permissions.permission_group_id) as permission_groups,
      COUNT(DISTINCT comments.gid) as comments
      FROM resources JOIN revisions ON revisions.resource_id=resources.id JOIN permissions ON permissions.id=revisions.permission_id
      LEFT OUTER JOIN comments ON comments.resource_id=resources.id JOIN permission_groups_permissions ON permission_groups_permissions.permission_id=permissions.id #{where_sql}
      GROUP BY resources.id ORDER BY #{sort_column} #{sort_direction} LIMIT #{offset},#{per_page};"

      # connection = ActiveRecord::Base.
      p query
      ActiveRecord::Base.connection.exec_query(query)
  end

  def resources_analysed_total_entries(filters, doSearch=true)
    if doSearch
      where_sql = create_where_statement filters
    else
      where_sql = ActiveRecord::Base.send(:sanitize_sql_array, ["WHERE resources.monitored_resource_id=%s AND mime_type !='application/vnd.google-apps.folder'", id])
    end

    query = "SELECT COUNT(resources.id) AS count FROM resources #{where_sql}"

    # connection = ActiveRecord::Base.connection
    result_set = ActiveRecord::Base.connection.exec_query(query)
    result_set.first['count']
  end

  def create_where_statement(filters)
    where = ["WHERE resources.monitored_resource_id=%s AND mime_type !='application/vnd.google-apps.folder'", id]

    filters.each do |key,value|
      case key
        when :sSearch
          where.first << " AND resources.title LIKE '%%%s%%'"
          where.push value
        when :filter_periods
          # all resources that have been modified (not only created)
          period = MonitoredPeriod.find( value.to_i )
          where.first << " AND (resources.modified_date > '#{period.start_date}' AND resources.modified_date < '#{period.end_date}' )"
        when :filter_mimetype
          if value.eql? 'GOOGLE_FILE_TYPES'
            where.first << " AND resources.mime_type IN ('#{ GOOGLE_FILE_TYPES.join("','") }')"
          else
            where.first << " AND resources.mime_type='%s'"
            where.push value
          end
        else
          # do nothing
      end
    end
    ActiveRecord::Base.send(:sanitize_sql_array, where)
  end

  def structure_indexed?
    return !structure_indexed_at.blank?
  end

  def mime_count
    mime_count = Hash.new
    mime_types = Resource.select(:mime_type).where(:monitored_resource_id => id).uniq

    mime_types.each do |r|
      mime_count[r.mime_type] = Resource.where(:monitored_resource_id => id, :mime_type => r.mime_type).count
    end

    mime_count
  end

  def update_metadata(user_token)
    metadata = DriveFiles.retrieve_file_metadata(self.gid, user_token)

    update_attributes(
      :created_date => metadata['createdDate'],
      :modified_date => metadata['modifiedDate'],
      :shared_with_me_date => metadata['sharedWithMeDate'],
      :owner_names => metadata['ownerNames'].join(", "),
      :title => metadata['title']
    )
  end

  def update_permissions(user_token)
    permissions = DriveFiles.retrieve_file_permissions(gid, user_token)
    permissions.each do |params|
      permission = Permission
        .where(:monitored_resource_id => id)
        .where(:gid => params['id'])
        .first_or_create

      permission.update_attributes(
          :name => params['name'],
          :email_address => params['emailAddress'],
          :domain => params['domain'],
          :role => params['role'],
          :perm_type => params['type'],
      )
    end

    resource_bound_permissions = Permission.where(:monitored_resource_id => id, :domain => nil)
    resource_bound_permissions.each do |permission|
      revision = Revision.select(:resource_id).where(:permission_id => permission.id).first
      resource = Resource.where(:id => revision.resource_id).first
      metadata = DriveFiles.retrieve_permission(resource['gid'], permission.gid, user_token)
      permission.update_attributes(
          :name => metadata['name'],
          :email_address => metadata['emailAddress'],
          :domain => metadata['domain'],
          :role => metadata['role'],
          :perm_type => metadata['type'],
      )
    end
  end


  # *** DELAYED TASKS - START
  def index_structure(user_id, user_token, file_id)
    resources = DriveFiles.retrieve_all_files_for(file_id, user_token)

    resources.each do |metadata|
      # @todo: next if .DS_Store or first char == '.'
      new_resource = Resource
        .where(:gid => metadata['id'])
        .where(:monitored_resource_id => id)
        .where(:user_id => user_id)
      .first_or_create

      new_resource.update_metadata(metadata)

      if new_resource.is_folder? # create new delayed_job, if type is folder
        index_structure(user_id, user_token, new_resource.gid)
      else # get revisions, comments (does not apply for folders, have none)
        unless (new_resource.is_folder? || new_resource.has_latest_revision?)
          new_resource.retrieve_revisions(user_token)
        end

        # fetch comments, (no possibility for a shortcut here)
        new_resource.retrieve_comments(user_token)

        # download revision for google resources, only needed for diffing revision
        #if new_resource.is_google_filetype?
        #  new_resource.download_revisions(user_token)
        #  #new_resource.calculate_revision_diffs
        #end
      end
    end
  end
  handle_asynchronously :index_structure, :queue => 'index_structure', :owner => Proc.new {|o| o}

  # this has to be done in a second step, as all diffing jobs have to be finished first
  def combine_revisions
    resources.google_resources.each do |resource|
      resource.find_collaborations
    end
  end
  handle_asynchronously :combine_revisions, :queue => 'combine_revisions', :owner => Proc.new {|o| o}
end