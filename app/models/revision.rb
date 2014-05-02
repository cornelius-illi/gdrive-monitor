require 'date'

class Revision < ActiveRecord::Base
  belongs_to :resource
  belongs_to :permission
  has_many :collaborations , class_name: '::Collaboration', :foreign_key => 'collaboration_id'

  JOIN_QUERY = 'SELECT * FROM collaborations WHERE collaborations.threshold=' + Collaboration::STANDARD_COLLABORATION_THRESHOLD.to_s

  scope :latest, -> { order('modified_date DESC').first }
  scope :with_collaboration, -> {
    joins('LEFT JOIN ('+JOIN_QUERY+') AS c ON c.revision_id=revisions.id')
    .where('c.id IS NULL')
  }

  WEAK_THRESHOLD_BASE = 1.freeze # divided with chars_count -> 1/100 = 0.01 = 1%, 1/1000 = 0.001 = 0.1%

  def self.count_weak(collection_of_revisions)
    nbr_weak = 0
    collection_of_revisions.each do |revision|
      nbr_weak += revision.is_weak? ? 1 : 0
    end
    return nbr_weak
  end

  def first_revision_in_session
    Revision
      .joins('JOIN collaborations ON collaborations.revision_id=revisions.id')
      .where('collaborations.collaboration_id=?', self.id)
      .where('collaborations.threshold=?', Collaboration::STANDARD_COLLABORATION_THRESHOLD)
      .order('modified_date ASC').first
  end

  def team_collaboration?
    permission_ids = [ permission_id ]
    collaborations.each do |collaboration|
      permission_ids << collaboration.permission_id
    end

    permission_ids.uniq!
    return (permission_ids.length > 1)
  end

  def collaboration_is_global?(monitored_resource_id=nil)
    return false if monitored_resource_id.nil?

    perm_ids = Array.new
    perm_ids << self.permission_id
    self.collaborations.each do |r|
      perm_ids << r.permission_id
    end
    # remove duplicates
    perm_ids.uniq!

    # definition: at least one permission from a different permission group
    perm_group_ids = Array.new
    # @todo: works only for n=2 perm-groups. need to look at n-1 groups
    group = PermissionGroup.where(:monitored_resource_id => monitored_resource_id).first

    # pre-condition
    return false if group.nil?

    group.permissions.each do |perm|
      perm_group_ids << perm.id
    end

    intersection = perm_ids & perm_group_ids
    # two cases are relevant: all match, none matches -> one group did all the work
    return !((intersection).length.eql?(perm_ids.length) || intersection.length.eql?(0))
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
        :etag => metadata['etag'],
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
    return Revision
      .where('resource_id=? AND modified_date < ?', resource_id, modified_date )
      .order('modified_date DESC').first
  end

  def collaboration_for(threshold)
    Collaboration.where(:revision_id => id).where(:threshold => threshold).first
  end

  def find_and_create_collaboration(skip_calculation_mode=false)
    previous = previous()
    # return, if there is no previous revision
    return if previous.blank?

    distance_in_seconds_list = skip_calculation_mode ? [ Collaboration::STANDARD_COLLABORATION_THRESHOLD ] : (3..40)
    distance_in_seconds_list.each do |var|
      threshold_in_seconds = (var*60).seconds
      if (modified_date - threshold_in_seconds) <= previous.modified_date
        collaboration = collaboration_for(threshold_in_seconds)
        master =  collaboration.blank? ? id : collaboration.collaboration_id

        Collaboration
          .where(:revision_id => previous.id)
          .where(:permission_id => previous.permission_id)
          .where(:threshold => threshold_in_seconds)
          .where(:collaboration_id => master)
          .where(:modified_date => previous.modified_date)
          .first_or_create
      end
    end

    previous.find_and_create_collaboration
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
  def self.analyse_revisions_for(monitored_resource_id, monitored_period, permission_id=nil)
    return nil if monitored_resource_id.blank?

    where = ["WHERE resources.monitored_resource_id=%s AND resources.mime_type !='application/vnd.google-apps.folder'", monitored_resource_id]
    unless monitored_period.blank? || !monitored_period.is_a?(MonitoredPeriod)
      where.first << " AND (resources.created_date > '#{monitored_period.start_date}' AND resources.created_date < '#{monitored_period.end_date}' )"
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
      result_hash[ Date::DAYNAMES[wday] ] = 0
    end

    result.each do |revision|
      result_hash[ Date::DAYNAMES[ revision['modified_date'].wday] ] += 1
    end

    return result_hash
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