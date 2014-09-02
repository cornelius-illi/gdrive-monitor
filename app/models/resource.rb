class Resource < ActiveRecord::Base
  belongs_to :monitored_resource, :foreign_key => 'monitored_resource_id'
  belongs_to :document_group, :foreign_key => 'document_group_id'

  has_many  :jobs, :class_name => "::Delayed::Job", :as => :owner
  has_many  :revisions, -> { order('modified_date DESC, permission_id DESC') }, :dependent => :delete_all
  has_many  :comments, :dependent => :delete_all

  #has_and_belongs_to_many :parents , class_name: '::Resource', :join_table => 'resources_parents', :foreign_key => 'parent_id'

  scope :google_resources, -> { where("mime_type IN('application/vnd.google-apps.drawing','application/vnd.google-apps.document','application/vnd.google-apps.spreadsheet','application/vnd.google-apps.presentation')") }
  scope :ungrouped, ->(doc_gr) { where("mime_type IN('#{ALL_WORKING_DOCUMENT_TYPES.join("','")}') AND (document_group_id IS NULL OR document_group_id=?)", doc_gr.id )}

  serialize :export_links, Hash

  GOOGLE_FOLDER_TYPE = 'application/vnd.google-apps.folder'.freeze
  GOOGLE_FILE_TYPES = %w(
    application/vnd.google-apps.drawing
    application/vnd.google-apps.document
    application/vnd.google-apps.spreadsheet
    application/vnd.google-apps.presentation
    application/vnd.google-apps.form
  )

  MICROSOFT_OFFICE_FILE_TYPES = %w(
    application/msword
    application/vnd.ms-excel
    application/vnd.ms-powerpoint
    application/vnd.openxmlformats-officedocument.presentationml.presentation
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
  )

  OPEN_OFFICE_FILE_TYPES = %w(
    application/vnd.oasis.opendocument.graphics
    application/vnd.oasis.opendocument.text
  )

  OFFICE_FILE_TYPES = MICROSOFT_OFFICE_FILE_TYPES.concat(OPEN_OFFICE_FILE_TYPES)
  # @todo: add adobe documents (indd) or rename to office_working ...
  WORKING_DOCUMENT_TYPES = GOOGLE_FILE_TYPES.concat(OFFICE_FILE_TYPES)

  ALL_WORKING_DOCUMENT_TYPES = WORKING_DOCUMENT_TYPES.concat(['application/pdf', 'application/octet-stream'])


  IMAGE_FILE_TYPE = 'image/jpeg'.freeze
  IMAGE_FILE_TYPES = %w(
    image/gif
    image/jpeg
    image/png
    image/svg+xml
    image/tiff
    image/x-canon-cr2
    image/x-icon
    image/x-photoshop
  ).freeze

  def self.find_with_several_revisions()
    query = 'SELECT resources.id, COUNT(revisions.id) as revisions FROM resources JOIN revisions ON revisions.resource_id=resources.id GROUP BY resources.id HAVING COUNT(revisions.id) > 1;'
    return ActiveRecord::Base.connection.exec_query(query)
  end

  def self.find_create_or_update_batched_for(child_resources, mr_id, user_id)
    child_resources.each do |resource|
      new_resource = Resource
        .where(:gid => resource['id'])
        .where(:monitored_resource_id => mr_id)
        .where(:user_id => user_id)
        .first_or_create
      
      # this also updates the existing once
      self.update_resource_attributes_for(new_resource, resource)
    end
  end

  def self.mimetypes_for_monitored_resource(mr_id)
    query = ActiveRecord::Base.send(:sanitize_sql_array, ["SELECT DISTINCT resources.mime_type as mime_type FROM resources WHERE monitored_resource_id=%s ORDER BY mime_type",mr_id])
    results = ActiveRecord::Base.connection.exec_query(query)
    [ ['--- none ---',''], ['GOOGLE_FILE_TYPES','GOOGLE_FILE_TYPES'] ].concat results.map {|result| [result['mime_type'], result['mime_type']]}
  end

  def doc_group_title
    rev = revisions.latest.blank? ? "" : "(#{revisions.latest.modified_date.to_date})"
    return "#{title} (#{parent_ids}) #{rev}"
  end

  def is_folder?
    return (mime_type.eql? 'application/vnd.google-apps.folder')
  end

  def is_google_filetype?
    return GOOGLE_FILE_TYPES.include?(mime_type)
  end

  def shortened_title(length = 35)
    st = title.size > length+5 ? [title[0,length],title[-5,5]].join("...") : title
    return is_folder? ? '<span class="fi-folder"></span> ' + st :  st
  end

  def collaborators
    h = Hash.new {|hash, key| hash[key] = 0}
    revisions.each do |r|
      # @todo: what if google data is incomplete?
      next if r.permission.nil? # sometimes google data is only partially available
      h[r.permission_id] += 1
    end
    return h
  end

  def global_collaboration?
    # definition: at least one permission from a different permission group
    perm_group_ids = Array.new
    # @todo: works only for n=2 perm-groups. need to look at n-1 groups
    group = PermissionGroup.where(:monitored_resource_id => monitored_resource_id).first

    # pre-condition
    return false if group.nil?

    group.permissions.each do |perm|
      perm_group_ids << perm.id
    end

    perm_ids = collaborators().keys
    intersection = perm_ids & perm_group_ids
    # two cases are relevant: all match, none matches -> one group did all the work
    return !((intersection).length.eql?(perm_ids.length) || intersection.length.eql?(0))
  end

  def self.count_sessions_per_distance_for(set=Array.new)
    result_set = Array.new
    set.each do |resource_id|
      result_set << Resource.find(resource_id).count_sessions_per_distance
    end

    (3..40).each do |minute|
      value_string = ''
      result_set.each_with_index do |member, index|
        value_string += ((index+1) < result_set.length) ? member[minute].to_s + ',' : member[minute].to_s
      end

      p minute.to_s + ',' + value_string
    end
  end

  def count_sessions_per_distance
    set = Hash.new
    (3..40).each do |minutes|
      seconds = minutes*60
      sql = 'SELECT COUNT(*) AS count FROM revisions
        LEFT JOIN (SELECT * FROM collaborations WHERE collaborations.threshold=?) AS c ON c.revision_id=revisions.id
        WHERE c.id IS NULL AND revisions.resource_id=?'
      query = ActiveRecord::Base.send(:sanitize_sql_array, [sql, seconds, self.id])
      results = ActiveRecord::Base.connection.exec_query(query)

      set[minutes] = results.first['count']
    end

    return set
  end

  # this method is meant to decrease requests send to google,
  # by checking if the latest revision has already been downloaded
  #
  # Problems/ @TODO:
  # md5_checksum does not exist for google-file-types
  # the latest version on google != the latest revision.
  # actually: the latest revision is the penultimate "version"
  def has_latest_revision?
    (md5_checksum.blank? || revisions.blank?) ? false : (md5_checksum.eql? revisions.latest.md5_checksum)
  end

  def revisions_by_permission_group
    # pre-condition: permissions always belong to distinct groups

    result = Hash.new {|hash, key| hash[key] = 0}
    permissions_mapping = Hash.new
    pgroups = PermissionGroup.where(:monitored_resource_id => monitored_resource_id)

    pgroups.each do |group|
      group.permissions.each do |p|
        permissions_mapping[p.id] = group.id
      end
    end

    revisions.each do |r|
      next if r.permission_id.nil?

      gid = permissions_mapping[r.permission_id]
      result[gid] += 1
    end

    return result
  end

  def update_metadata(metadata, user_token)
    google_permission_id = metadata['owners'].first['permissionId']
    permission_id = nil

    unless google_permission_id.blank?
      permission = Permission
        .where(:gid => metadata['owners'].first['permissionId'] )
        .where(:monitored_resource_id => monitored_resource_id )
      .first_or_initialize

      # if permission has just been created, get metadata
      if permission.id.blank?
        perm_metadata = DriveFiles.retrieve_permission(gid,permission.gid, user_token)
        permission.update_attributes(
            :name => perm_metadata['name'],
            :email_address => perm_metadata['emailAddress'],
            :domain => perm_metadata['domain'],
            :role => perm_metadata['role'],
            :perm_type => perm_metadata['type']
        )
      end

      permission_id = permission.id
    end

    # find the parent object
    parent_gid = metadata['parents'].blank? ? nil : metadata['parents'].first['id']
    parent_id = nil
    unless parent_gid.blank?
      parent_resource = Resource
        .where(:gid => parent_gid)
        .where(:monitored_resource_id => monitored_resource_id )
        .first_or_initialize

      if parent_resource.id.blank?
        parent_meta = DriveFiles.retrieve_file_metadata(parent_gid, user_token)
        unless parent_meta.blank? # parent can also be unreachable (404)
          parent_resource.update_metadata(parent_meta, user_token)
        end
      end

      parent_id = parent_resource.id
    end

    # NOTICE: sometimes files have createdDates in the future, therefore we always search for the first revision.
    # If the date of the first revision is < creadedDate, then this one is used instead
    first_revision = Revision.where(:resource_id => id).order('modified_date ASC').first
    unless first_revision.nil?
      created_date = DateTime.parse( metadata['createdDate'] )
      metadata['createdDate'] = first_revision.modified_date if created_date > first_revision.modified_date
    end

    # NOTICE: sometimes files that origin from downloaded resources have old modified_dates.
    # the createdDate on google hence is greater then the modified date, which will mess up the listings.
    # Therefore it is altered here to avoid problems.
    metadata['modifiedDate'] = metadata['createdDate'] if metadata['modifiedDate'] < metadata['createdDate']

    update(
        :alternate_link => metadata['alternateLink'],
        :created_date => metadata['createdDate'],
        :icon_link => metadata['iconLink'],
        :export_links => metadata['exportLinks'],
        :md5_checksum => metadata['md5Checksum'],
        :file_extension => metadata['fileExtension'],
        :file_size => metadata['fileSize'],
        :kind => metadata['kind'],
        :owner_names => metadata['ownerNames'].join(", "),
        :last_modifying_username => metadata['lastModifyingUserName'],
        :mime_type => metadata['mimeType'],
        :modified_date => metadata['modifiedDate'],
        :shared => metadata['shared'],
        :trashed => metadata['labels']['trashed'],
        :viewed => metadata['labels']['viewed'],
        :parent_ids => parent_id,
        :title => metadata['title'],
        :permission_id => permission_id
      )
  end

  def download_path
    return "public/resources/r-#{id.to_s}"
  end

  # REPORT RELATED QUERIES - START
  def self.analyse_new_resources_for(monitored_resource_id, monitored_period)
    return nil if monitored_resource_id.blank?

    where = ["WHERE resources.monitored_resource_id=%s AND mime_type !='application/vnd.google-apps.folder'", monitored_resource_id]
    unless monitored_period.blank? || !monitored_period.is_a?(MonitoredPeriod)
      where.first << " AND (resources.created_date > '#{monitored_period.start_date}' AND resources.created_date < '#{monitored_period.end_date}' )"
    end

    where_sql = ActiveRecord::Base.send(:sanitize_sql_array, where)

    query = "SELECT COUNT(resources.id) as resources FROM resources #{where_sql}"
    result = ActiveRecord::Base.connection.exec_query(query)
    result.first['resources']
  end

  def self.count_working_documents()
    Resource.where("mime_type IN ('#{ WORKING_DOCUMENT_TYPES.join("','") }')").count
  end

  def self.analyse_modified_resources_for(monitored_resource_id, monitored_period, mime_type_collection=nil)
    return nil if monitored_resource_id.blank?

    where = ["WHERE resources.monitored_resource_id=%s AND mime_type !='application/vnd.google-apps.folder'", monitored_resource_id]
    unless monitored_period.blank? || !monitored_period.is_a?(MonitoredPeriod)
      where.first << " AND (revisions.modified_date >= '#{monitored_period.start_date}' AND revisions.modified_date <= '#{monitored_period.end_date}' )"
    end

    unless mime_type_collection.blank?
      where.first << " AND resources.mime_type IN ('#{ mime_type_collection.join("','") }')"
    end

    where_sql = ActiveRecord::Base.send(:sanitize_sql_array, where)

    query = "SELECT COUNT(DISTINCT resources.id) as resources FROM resources JOIN revisions ON revisions.resource_id=resources.id #{where_sql}"
    result = ActiveRecord::Base.connection.exec_query(query)
    result.first['resources']
  end

  def self.google_resources_for_period(monitored_resource, period)
    Resource
      .where(:monitored_resource_id => monitored_resource.id)
      .where('resources.modified_date > ? AND resources.modified_date <= ?', period.start_date, period.end_date)
      .where("mime_type IN('#{GOOGLE_FILE_TYPES.join("','")}')")
  end

  def self.timespan
    query = 'SELECT MIN(created_date) as min, MAX(created_date) as max FROM resources;'
    result = ActiveRecord::Base.connection.exec_query(query)
    return result.first
  end

  def self.count_google_resources
    Resource
      .where("mime_type IN('#{GOOGLE_FILE_TYPES.join("','")}')")
      .count()
  end

  def self.count_office_resources
    Resource
      .where("mime_type IN('#{MICROSOFT_OFFICE_FILE_TYPES.join("','")}')")
      .count()
  end

  def self.count_openoffice_resources
    Resource
    .where("mime_type IN('#{OPEN_OFFICE_FILE_TYPES.join("','")}')")
    .count()
  end

  def self.count_images
    Resource
      .where("mime_type IN('#{IMAGE_FILE_TYPES.join("','")}')")
      .count()
  end

  def self.with_single_revision
    query = "SELECT COUNT(rr.id) AS count FROM (SELECT res.id
        FROM resources res JOIN revisions rev ON rev.resource_id=res.id
        WHERE res.mime_type != '#{GOOGLE_FOLDER_TYPE}'
        GROUP BY res.id HAVING COUNT(rev.id) = 1) rr"

    result = ActiveRecord::Base.connection.exec_query(query)
    result.first['count']
  end

  def self.with_single_images
    query = "SELECT COUNT(rr.id) AS count FROM (SELECT res.id
        FROM resources res JOIN revisions rev ON rev.resource_id=res.id
        WHERE res.mime_type IN('#{IMAGE_FILE_TYPES.join("','")}')
        GROUP BY res.id HAVING COUNT(rev.id) = 1) rr"

    result = ActiveRecord::Base.connection.exec_query(query)
    result.first['count']
  end

  def self.with_single_revision_same_latest
    query = 'SELECT COUNT(rr.id) as count FROM (SELECT res.id, res.mime_type, res.modified_date AS m1, rev.modified_date AS m2
      FROM resources res JOIN revisions rev ON rev.resource_id=res.id GROUP BY res.id HAVING COUNT(rev.id) = 1) rr WHERE rr.m1 = rr.m2'

    result = ActiveRecord::Base.connection.exec_query(query)
    result.first['count']
  end

  def self.with_single_revision_different_latest
    query = 'SELECT COUNT(rr.id) as count FROM (SELECT res.id, res.mime_type, res.modified_date AS m1, rev.modified_date AS m2
      FROM resources res JOIN revisions rev ON rev.resource_id=res.id GROUP BY res.id HAVING COUNT(rev.id) = 1) rr WHERE rr.m1 != rr.m2'

    result = ActiveRecord::Base.connection.exec_query(query)
    result.first['count']
  end

  def self.with_single_revision_latest_eql_one
    query = 'SELECT COUNT(aa.id) AS count FROM
      (SELECT rr.id, rr.mime_type, rr.m1, rr.m2, ABS(TIMESTAMPDIFF(SECOND, rr.m1, rr.m2)) as diff
      FROM (SELECT res.id, res.mime_type, res.modified_date AS m1, rev.modified_date AS m2
      FROM resources res JOIN revisions rev ON rev.resource_id=res.id GROUP BY res.id HAVING COUNT(rev.id) = 1) rr) aa WHERE aa.diff = 1'
    result = ActiveRecord::Base.connection.exec_query(query)
    result.first['count']
  end

  def self.topten_mime_types
    query = "SELECT res.mime_type AS mime_type, COUNT(res.id) AS count FROM resources res
      WHERE res.monitored_resource_id AND res.mime_type != 'application/vnd.google-apps.folder'
      GROUP BY mime_type ORDER BY COUNT(res.id) DESC LIMIT 15;"
    return ActiveRecord::Base.connection.exec_query(query)
  end

  def self.topten_mime_types_revisions_box_plot
    top_ten = Resource.topten_mime_types

    result_set = Hash.new
    result_set['categories'] = Array.new
    result_set['data'] = Array.new

    top_ten.each do |row|
      result_set['categories'] << row['mime_type']
      values = Array.new

      query_mime = ['SELECT res.id, COUNT(rev.id) AS count FROM resources res JOIN revisions rev ON rev.resource_id=res.id
        WHERE res.mime_type=? GROUP BY res.id ORDER BY COUNT(rev.id) ASC', row['mime_type']]
      sql = ActiveRecord::Base.send(:sanitize_sql_array, query_mime)
      mime_res = ActiveRecord::Base.connection.exec_query(sql)

      mime_res.each do |mime_row|
        values << mime_row['count']
      end

      set = Array.new

      # lower adjacent
      set << values.min

      # lower hinge (25th percentile)
      up_hinge_rank = 0.25 * (values.length)
      ir_rank = up_hinge_rank.to_i

      up_hinge_fraction = up_hinge_rank - up_hinge_rank.to_i

      if up_hinge_fraction.eql? 0.0
        set << values[ir_rank]
      else
        if (ir_rank+1) >= values.length
          set << values[ir_rank]
        else
          interpolation = (up_hinge_fraction * (values[ir_rank+1] - values[ir_rank])) + values[ir_rank]
          set << interpolation
        end
      end

      # Median (50th percentile)
      up_hinge_rank = 0.50 * (values.length)
      ir_rank = up_hinge_rank.to_i
      up_hinge_fraction = up_hinge_rank - up_hinge_rank.to_i
      if up_hinge_fraction.eql? 0.0
        set << values[ir_rank]
      else
        if (ir_rank+1) >= values.length
          set << values[ir_rank]
        else
          interpolation = (up_hinge_fraction * (values[ir_rank+1] - values[ir_rank])) + values[ir_rank]
          set << interpolation
        end
      end

      # upper hinge (75th percentile)
      up_hinge_rank = 0.75 * (values.length)
      ir_rank = up_hinge_rank.to_i
      up_hinge_fraction = up_hinge_rank - up_hinge_rank.to_i
      if up_hinge_fraction.eql? 0.0
        set << values[ir_rank]
      else
        if (ir_rank+1) >= values.length
          set << values[ir_rank]
        else
          interpolation_75 = (up_hinge_fraction * (values[ir_rank+1] - values[ir_rank])) + values[ir_rank]
          set << interpolation_75
        end
      end

      # upper adjacent, whiskers
      set << values.max

      # tukey plot - START - lines in between can be commented out, if min/ max is better
      iqr_1_5 = (set[3] - set[1]) * 1.5

      limit_lower_hinge = (set[1] - iqr_1_5) < 0 ? 0 :  (set[1] - iqr_1_5)
      set[0] = values.min { |a,b| (a-limit_lower_hinge).abs <=> (b-limit_lower_hinge).abs }

      limit_upper_hinge = set[3] + iqr_1_5
      set[4] = values.min { |a,b| (a-limit_upper_hinge).abs <=> (b-limit_upper_hinge).abs }
      # tukey plot - END

      result_set['data'] << set
    end

    return result_set
  end

  # REPORT RELATED QUERIES - STOP


  # *** DELAYED TASKS - START
  def retrieve_and_update_metadata(token)
    metadata = DriveFiles.retrieve_file_metadata(gid, token)

    # if nil then 404 - file is not reachable anymore
    if metadata.blank?
      update(:unavailable => true)
    else
      update_metadata(metadata, token)
    end
  end
  handle_asynchronously :retrieve_and_update_metadata, :queue => 'metadata', :owner => Proc.new {|o| o}


  def retrieve_comments(user_token)
    return unless is_google_filetype? # only for google_file_types

    comments = DriveComments.retrieve_comments_list(gid, user_token)
    comments.each do |metadata|
      new_comment = Comment
        .where(:gid => metadata['commentId'])
        .where(:resource_id => id)
        .first_or_create
      new_comment.update_metadata(metadata)

      # handle replies, a resource_id is not set explicitly
      metadata['replies'].each do |reply_meta|
        new_reply = Comment
          .where(:gid => reply_meta['replyId'])
          .where(:comment_id => new_comment.id )
          .first_or_create
        new_reply.update_reply_metadata(reply_meta)
      end
    end
  end
  handle_asynchronously :retrieve_comments, :queue => 'comments', :owner => Proc.new {|o| o}

  def retrieve_revisions(user_token)
    return if is_folder? # results in: 400 Bad Request

    revisions = DriveRevisions.retrieve_revisions_list( gid, user_token )

    revisions.each do |metadata|
      # sometimes no lastModifyingUser is available, then exclude from stats
      next unless metadata.has_key?('lastModifyingUser')
      new_revision = Revision
        .where(:gid => metadata['id'])
        .where(:resource_id => id)
        .first_or_initialize

      # if the revision is new
      if new_revision.id.blank?
        permission = Permission
          .where(:gid => metadata['lastModifyingUser']['permissionId'] )
          .where(:monitored_resource_id => monitored_resource.id )
          .first_or_initialize

          # if permission has just been created, get metadata
          # @todo: refactoring -> should be done inside permission model
          if permission.id.blank?
            perm_metadata = DriveFiles.retrieve_permission(gid,permission.gid, user_token)
            permission.update_attributes(
                :name => perm_metadata['name'],
                :email_address => perm_metadata['emailAddress'],
                :domain => perm_metadata['domain'],
                :role => perm_metadata['role'],
                :perm_type => perm_metadata['type'],
            )
          end

        new_revision.update_metadata(metadata, permission.id)
      end

      # @todo: can be put inside upper block, once all old once have been updated
      new_revision.calculate_time_distance_to_previous
    end
  end
  handle_asynchronously :retrieve_revisions, :queue => 'revisions', :owner => Proc.new {|o| o}


  def create_working_sessions()
    # 401 error - some revisions could not be fetched
    return if revisions.empty?

    # reset before creation
    Revision.where(:resource_id => id).update_all("working_session_id = NULL, collaboration = NULL")

    revisions.latest.create_working_sessions
    revisions.first_in_working_sessions.each do |rev|
      rev.detect_collaboration
    end
  end
  handle_asynchronously :create_working_sessions, :queue => 'revisions', :owner => Proc.new {|o| o}

  def calculate_all_working_sessions()
    # 401 error - some revisions could not be fetched
    return if revisions.empty?

    revisions.first.calculate_all_working_sessions
  end
  handle_asynchronously :calculate_all_working_sessions, :queue => 'revisions', :owner => Proc.new {|o| o}


  ### DEPRECATED ###

  def download_revisions(token)
    # pre-condition: revisions should only be downloaded for diffing and diffing only makes sense for text-based resource formats
    return if is_folder? || !is_google_filetype?

    unless File.directory?( download_path )
      FileUtils.mkdir_p( download_path )
    end

    revisions.each do |revision|
      file_path = File.join( download_path, revision.gid) + '.' + revisions_download_format
      # skip, if downloaded before
      next if File.exists?(file_path)

      download_revision(revision.gid,file_path,token)
    end

    # download the current version
    current = "current-#{modified_date.to_time.to_i}.#{revisions_download_format}"
    current_path = File.join( download_path, current)
    unless File.exists?(current_path)
      # delete all files that were previously downloaded as THE current version
      Dir.glob( "#{download_path}/current-*" ).each { |f| File.delete(f) }
      # nil is for current
      download_revision(nil,current_path,token)
    end
  end
  handle_asynchronously :download_revisions, :queue => 'downloads', :owner => Proc.new {|o| o}


  def download_revision(revision,path,token)
    response = DriveFiles.download( download_revision_link(revision), token)
    if response
      File.open(path, "wb") { |f| f.write( response ) }
    end
  end
  handle_asynchronously :download_revision, :queue => 'downloads', :owner => Proc.new {|o| o}


  def calculate_revision_diffs(again=false)
    revisions.each do |revision|
      revision.calculate_diff(again)
    end
  end
  handle_asynchronously :calculate_revision_diffs, :queue => 'diffing', :owner => Proc.new {|o| o}
  # *** DELAYED TASKS - END
end