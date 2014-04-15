class Revision < ActiveRecord::Base
  belongs_to :resource
  belongs_to :permission
  has_many :merged, class_name: 'Revision'
  has_many :collaboration, class_name: 'Revision', :foreign_key => 'collaboration_id'

  scope :latest, -> { order('modified_date DESC').first }
  scope :exclude_merged, -> { where(:revision_id => nil).order('modified_date DESC') }
  scope :exclude_collaborated_and_merged, -> {
    where('(revision_id IS NULL AND collaboration_id IS NULL)').order('modified_date DESC') }

  MERGE_TIME_THRESHOLD = 8.minutes.freeze
  WEAK_THRESHOLD_BASE = 1.freeze # divided with chars_count -> 1/100 = 0.01 = 1%, 1/1000 = 0.001 = 0.1%

  def self.count_weak(collection_of_revisions)
    nbr_weak = 0
    collection_of_revisions.each do |revision|
      nbr_weak += revision.is_weak? ? 1 : 0
    end
    return nbr_weak
  end

  def self.collaboration_is_global?(collection_of_revisions, monitored_resource_id=nil)
    return false if monitored_resource_id.nil?

    perm_ids = Array.new
    collection_of_revisions.each do |revision|
      perm_ids << revision.permission_id
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
    # FIELDS: deleted,file(etag,lastModifyingUserName),fileId,id,modificationDate
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

  def previous
    Revision
      .where('resource_id=? AND modified_date < ?', resource_id, modified_date )
      .order('modified_date DESC').first
  end

  def merge_consecutive
    previous = previous()
    # return, if there is no previous revision or it has already been set (due to recursion)
    return if previous.blank? || !previous.revision_id.blank?

    # same modifier + max. X minutes in between revision
    if (permission_id.eql? previous.permission_id) &&
        ((modified_date - MERGE_TIME_THRESHOLD) <= previous.modified_date)
      # previous will be merged with me. latest revision stays
      master = revision_id.blank? ? id : revision_id
      previous.update_attribute(:revision_id, master)
    end

    previous.merge_consecutive
  end

  def find_and_create_collaboration
    previous = previous()
    # return, if there is no previous revision
    return if previous.blank?

    my_master = revision_id.blank? ? id : revision_id

    if ((permission_id != previous.permission_id) &&
        ((modified_date - MERGE_TIME_THRESHOLD) <= previous.modified_date)) ||
        (my_master.eql? previous.revision_id)

      master = id
      if collaboration_id.blank? && !revision_id.blank?
        master = revision_id
      elsif !collaboration_id.blank? && revision_id.blank?
        master = collaboration_id
      elsif !collaboration_id.blank? && !revision_id.blank?
        master = collaboration_id
      end

      previous.update_attribute(:collaboration_id, master)
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
    result = ActiveRecord::Base.connection.execute(query)
    result.first['revisions']
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