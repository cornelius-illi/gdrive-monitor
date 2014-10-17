require 'date'

class Revision < ActiveRecord::Base
  belongs_to :resource
  belongs_to :permission
  has_many :revisions , class_name: '::Revision', :foreign_key => 'working_session_id', :order => 'modified_date DESC, permission_id DESC'

  # latest revision of a file
  scope :latest, -> { order('modified_date DESC, permission_id DESC').first }

  scope :activities, -> { where('revisions.working_session_id IS NULL').order('modified_date DESC, permission_id DESC') }

  # select all revisions that have joinable revisions via working_session_id
  scope :first_in_working_sessions, -> { joins('JOIN revisions r ON r.working_session_id=revisions.id ').group('revisions.id') }

  WEAK_THRESHOLD_BASE = 1.freeze # divided with chars_count -> 1/100 = 0.01 = 1%, 1/1000 = 0.001 = 0.1%

  def self.count_revisions_google_files
    query = "SELECT SUM(a.count) as count FROM
      (SELECT res.id, COUNT(rev.id) as count FROM revisions rev
        JOIN resources res ON rev.resource_id = res.id
        WHERE res.mime_type IN ('#{Resource::GOOGLE_FILE_TYPES.join("','")}') GROUP BY res.id) a"
    result = ActiveRecord::Base.connection.exec_query(query)
    return result.first['count']
  end

  def self.timespan
    return {
        'min' => ::DateTime.strptime("2013-10-28 21:46:09", '%Y-%m-%d %H:%M:%S'),
        'max' => ::DateTime.strptime("2014-07-25 11:38:17", '%Y-%m-%d %H:%M:%S')
    }

    #query = 'SELECT STR_TO_DATE("2013-10-28 21:46:09", "%Y-%m-%d") as min, MAX(modified_date) as max FROM revisions;'
    #result = ActiveRecord::Base.connection.exec_query(query)
    #return result.first
  end

  def first_revision_in_session
    rev_id = collaboration.blank? ? (working_session_id.blank? ? self : Revision.find(working_session_id)) : self
    Revision.where(:working_session_id => rev_id).order(modified_date: :asc).first
  end

  def team_collaboration?
    # for head-revisions of working sessions and single activities
    if working_session_id.blank?
      team_collaboration =  (!collaboration.blank? && collaboration > 0)
    else
      # if it is a revision that is part of an working session, find the head-revision first
      head_revision = Revision.find(working_session_id)
      team_collaboration = (head_revision.blank? && head_revision.collaboration > 0)
    end

    return team_collaboration
  end

  def collaboration_is_global?
    # for head-revisions of working sessions and single activities
    if working_session_id.blank?
      global_collaboration =  (!collaboration.blank? && collaboration > 1)
    else
      # if it is a revision that is part of an working session, find the head-revision first
      head_revision = Revision.find(working_session_id)
      global_collaboration = (head_revision.blank? && head_revision.collaboration > 1)
    end

    # collaboration holds the number of distinct permission-groups, or 0 if only one permission is part of the session
    return global_collaboration
  end

  def revisions_permissions_id_list
    permission_list = Array.new
    permission_list << permission_id
    permission_list.concat revisions.map {|n| n.permission_id}
    permission_list.uniq!
    return permission_list.join(",")
  end

  def detect_collaboration
    # if it is not the head-revision of a session.
    return false unless working_session_id.blank?

    # NULL = activity, 0 = Working Session, 1-N = (Global) CollaborationAggregate
    collaboration = 0

    # get all permission-ids of revisions that are part of the working session
    permission_ids = [ permission_id ]
    revisions.each do |revision|
      permission_ids << revision.permission_id
    end

    permission_ids.uniq!

    # collaboration only when there are more than 1 permissions involved
    if permission_ids.length > 1
      uniq_perm_id_list = permission_ids.join(',')

      # get the number of permission groups that are part of the working session
      mr_id = resource.monitored_resource_id
      query = "SELECT COUNT(DISTINCT pgp.permission_group_id) as perm_groups FROM permissions p JOIN permission_groups_permissions pgp ON p.id=pgp.permission_id WHERE p.monitored_resource_id=#{mr_id} AND p.id IN (#{uniq_perm_id_list})"
      result = ActiveRecord::Base.connection.exec_query(query)

      # in case no groups have been defined, 1 should be returned as pre-condition (permission_ids.length > 1) has already been fulfilled.
      collaboration =  (result.first['perm_groups'] > 0) ? result.first['perm_groups'] : 1
    end

    Revision.find(id).update(collaboration: collaboration)
    return collaboration
  end

  def total_percental_change
    result = percental_change.blank? ? 0.0 : percental_change
    if !collaboration.nil?
      collaboration.each do |revision|
        # additive is using absolute value in this case
        result += revision.percental_change.blank? ? 0.0 : revision.percental_change
      end
    elsif !merged.nil?
      merged.each do |revision|
        # additive is using absolute value in this case
        result += revision.percental_change.blank? ? 0.0 : revision.percental_change
      end
    end
    return result
  end

  def total_percental_add_abs
    result = percental_add.blank? ? 0.0 : percental_add.abs
    if !collaboration.nil?
      collaboration.each do |revision|
        # additive is using absolute value in this case
        result += revision.percental_add.blank? ? 0.0 : revision.percental_add.abs
      end
    elsif !merged.nil?
      merged.each do |revision|
        # additive is using absolute value in this case
        result += revision.percental_add.blank? ? 0.0 : revision.percental_add.abs
      end
    end
    return result
  end

  def total_percental_add
    result = percental_add.blank? ? 0.0 : percental_add
    if !collaboration.nil?
      collaboration.each do |revision|
        # additive is using absolute value in this case
        result += revision.percental_add.blank? ? 0.0 : revision.percental_add
      end
    elsif !merged.nil?
      merged.each do |revision|
        # additive is using absolute value in this case
        result += revision.percental_add.blank? ? 0.0 : revision.percental_add
      end
    end
    return result
  end

  def update_metadata(metadata, permission)
    # FIELDS: deleted,file(lastModifyingUserName),fileId,id,modificationDate
    update_attributes(
        :file_size => metadata['fileSize'],
        :md5_checksum => metadata['md5Checksum'],
        :permission_id => permission,
        :modified_date => metadata['modifiedDate'],
    )
  end

  def has_local_resource?
    File.exists? local_resource_path
  end

  def local_resource_path
    "public/resources/r-#{resource_id.to_s}/#{gid}.txt"
  end

  def local_resource_path_web
    "/resources/r-#{resource_id.to_s}/#{gid}.txt"
  end

  def set_is_weak
    is_weak = (total_percental_change < (weak_threshold)) ? (total_percental_add_abs < (weak_threshold)) : false
    is_weak = false if previous().nil?
    update_attribute(:is_weak, is_weak)
  end

  def calculate_time_distance_to_previous
    return unless self.distance_to_previous.blank?

    pr = previous
    unless pr.blank?
      diff = (modified_date - pr.modified_date).to_i
      self.distance_to_previous = diff
      save!
    end
  end

  def previous
    # WARNING: this method can cause troubles, when using MySQL and modified_date as datetime(0) which is the standard.
    return Revision
      .where('resource_id=? AND ((modified_date = ? AND id < ?) OR modified_date < ?)', resource_id, modified_date, id, modified_date )
      .order('modified_date DESC, id DESC').first
  end

  # tries to aggregate revisions to working sessions
  # pre-condition: requires to start with the latest revision.
  # then recursivly creates working sessions
  def create_working_sessions()
    previous = previous()
    # return, if there is no previous revision
    return if previous.blank?

    threshold_in_seconds = CollaborativeSession::STANDARD_COLLABORATION_THRESHOLD
    if (modified_date - threshold_in_seconds) <= previous.modified_date
      # am I already part of a working session? ... then continue session, else create new with my id
      working_session = working_session_id.blank? ?  id : working_session_id

      previous.update(
          working_session_id: working_session
      )
    end

    previous.create_working_sessions()
  end

  def collaboration_for(threshold)
    CollaborationAggregate.where(:revision_id => id).where(:threshold => threshold).first
  end

  def calculate_all_working_sessions()
    previous = previous()
    # return, if there is no previous revision
    return if previous.blank?

    distance_in_seconds_list = (3..40)
    distance_in_seconds_list.each do |threshold_in_seconds|
      if (modified_date - threshold_in_seconds) <= previous.modified_date
        collaboration = collaboration_for(threshold_in_seconds)
        master =  collaboration.blank? ? id : collaboration.collaboration_id

        CollaborationAggregate
          .where(:revision_id => previous.id)
          .where(:permission_id => previous.permission_id)
          .where(:threshold => threshold_in_seconds)
          .where(:collaboration_id => master)
          .where(:modified_date => previous.modified_date)
          .first_or_create
      end
    end

    previous.calculate_all_working_sessions()
  end

  def collaboration_length
    length = 1 # self
    collaboration.each do |revision|
      merged = Revision.where(:revision_id => revision.id).count(:id)
      length += merged.to_i + 1
    end
    return length
  end

  # REPORT RELATED QUERIES - START
  def self.count_for(monitored_resource_id, dates=nil, permission_id=nil)
    return nil if monitored_resource_id.blank?

    where = ["WHERE resources.monitored_resource_id=%s AND resources.mime_type !='application/vnd.google-apps.folder'", monitored_resource_id]
    unless dates.blank? || !dates.is_a?(Hash)
      where.first << " AND (revisions.modified_date >= '#{dates['start_date']}' AND revisions.modified_date <= '#{dates['end_date']}' )"
    end

    unless permission_id.blank?
      where.first << " AND revisions.permission_id=%s"
      where.push permission_id
    end

    where = ActiveRecord::Base.send(:sanitize_sql_array, where)

    query = "SELECT COUNT(revisions.id) as revisions FROM resources JOIN revisions ON revisions.resource_id=resources.id #{where}"
    result = ActiveRecord::Base.connection.exec_query(query)
    result.first['revisions']
  end

  def self.analyse_revisions_for(monitored_resource_id, monitored_period, permission_id=nil)
    return nil if monitored_resource_id.blank?

    where = ["WHERE resources.monitored_resource_id=%s AND resources.mime_type !='application/vnd.google-apps.folder'", monitored_resource_id]
    unless monitored_period.blank? || !monitored_period.is_a?(MonitoredPeriod)
      where.first << " AND (revisions.modified_date >= '#{monitored_period.start_date}' AND revisions.modified_date <= '#{monitored_period.end_date}' )"
    end

    unless permission_id.blank?
      where.first << " AND revisions.permission_id=%s"
      where.push permission_id
    end

    where = ActiveRecord::Base.send(:sanitize_sql_array, where)

    query = "SELECT COUNT(revisions.id) as revisions FROM resources JOIN revisions ON revisions.resource_id=resources.id #{where}"
    result = ActiveRecord::Base.connection.exec_query(query)
    result.first['revisions']
  end

  def self.count_workdays_for(monitored_resource_id, monitored_period, permission_group=nil)
    return nil if monitored_resource_id.blank?

    where = ["WHERE resources.monitored_resource_id=? AND resources.mime_type !='application/vnd.google-apps.folder'", monitored_resource_id]
    unless monitored_period.blank? || !monitored_period.is_a?(MonitoredPeriod)
      where.first << " AND (revisions.modified_date >= ? AND revisions.modified_date <= ? )"
      where.push monitored_period.start_date
      where.push monitored_period.end_date
    end

    unless permission_group.blank?
      permission_ids = permission_group.permissions.map {|p| p.id }
      where.first << " AND revisions.permission_id IN (#{permission_ids.join(',')})"
    end

    where = ActiveRecord::Base.send(:sanitize_sql_array, where)
    query = "SELECT COUNT(DISTINCT DATE(revisions.modified_date)) as workdays FROM resources JOIN revisions ON revisions.resource_id=resources.id #{where}"
    result = ActiveRecord::Base.connection.exec_query(query)
    return result.first['workdays']
  end

  def self.count_revisions_by_weekday(monitored_resource_id, monitored_period, permission_group=nil)
    return nil if monitored_resource_id.blank?

    where = ["WHERE resources.monitored_resource_id=? AND resources.mime_type !='application/vnd.google-apps.folder'", monitored_resource_id]
    unless monitored_period.blank? || !monitored_period.is_a?(MonitoredPeriod)
      where.first << " AND (resources.created_date > ? AND resources.created_date < ? )"
      where.push monitored_period.start_date
      where.push monitored_period.end_date
    end

    unless permission_group.blank?
      permission_ids = permission_group.permissions.map {|p| p.id }
      where.first << " AND revisions.permission_id IN (#{permission_ids.join(',')})"
    end

    where = ActiveRecord::Base.send(:sanitize_sql_array, where)
    query = "SELECT revisions.modified_date AS modified_date FROM resources JOIN revisions ON revisions.resource_id=resources.id #{where}"
    result = ActiveRecord::Base.connection.exec_query(query)

    result_hash= Hash.new
    (0..6).each do |wday|
      result_hash[ Date::ABBR_DAYNAMES[wday] ] = 0
    end

    result.each do |revision|
      result_hash[ Date::ABBR_DAYNAMES[ revision['modified_date'].wday] ] += 1
    end

    return result_hash.sort_by {|k,v| v}.reverse.first 3
  end

  def self.count_revisions_by_permissiongroup(monitored_resource_id, monitored_period, permission_group=nil)
    return nil if monitored_resource_id.blank?

    where = ["WHERE resources.monitored_resource_id=? AND resources.mime_type !='application/vnd.google-apps.folder'", monitored_resource_id]
    unless monitored_period.blank? || !monitored_period.is_a?(MonitoredPeriod)
      where.first << " AND (resources.created_date > ? AND resources.created_date < ? )"
      where.push monitored_period.start_date
      where.push monitored_period.end_date
    end

    unless permission_group.blank?
      permission_ids = permission_group.permissions.map {|p| p.id }
      where.first << " AND revisions.permission_id IN (#{permission_ids.join(',')})"
    end

    where = ActiveRecord::Base.send(:sanitize_sql_array, where)
    query = "SELECT COUNT(revisions.id) as nbr_revisions FROM resources JOIN revisions ON revisions.resource_id=resources.id #{where}"
    result = ActiveRecord::Base.connection.exec_query(query)


    return result.first['nbr_revisions']
  end
  # REPORT RELATED QUERIES - START

  # DELAYED - START
  def calculate_diff(again=false)
    # pre-conditions: has to be a google-file-type and local resource has to be available
    return unless (resource.is_google_filetype? || has_local_resource?)

    # do not calculate again, unless requested
    return if (!(percental_change.blank? || percental_add.blank?) && (not again))

    previous = previous()
    return if previous.blank? || !previous.has_local_resource?

    # chars
    chars = File.read(local_resource_path)
    chars_prev = File.read(previous.local_resource_path)
    chars_changes = calculate_changes(chars, chars_prev)

    # words
    words = chars.split
    words_prev = chars_prev.split
    words_changes = calculate_changes(words, words_prev)

    # lines
    lines = chars.split(%r{\r\n})
    lines_prev = chars_prev.split(%r{\r\n})
    lines_changes = calculate_changes(lines, lines_prev)

    update_attributes(
        :chars_changes => chars_changes,
        :chars_count => chars.length,
        :words_changes => words_changes,
        :words_count => words.length,
        :lines_changes => lines_changes,
        :lines_count => lines.length,
        :percental_change => (chars_changes/chars_prev.length.to_f),
        :percental_add => ((chars.length-chars_prev.length)/chars_prev.length.to_f)
    )
  end
  handle_asynchronously :calculate_diff, :queue => 'diffing', :owner => Proc.new {|o| o}
  # DELAYED - END

  private
  def calculate_changes(seq1,seq2)
    diff =  Diff::LCS.diff( seq1, seq2 )
    return (diff.length.eql? 0) ? 0 : diff[0].length
  end

  def weak_threshold
    # linear threshold
    x = chars_count.blank? ? 100 : chars_count
    return 1.0 / (x/10 * Math.log10(x) )
  end
end