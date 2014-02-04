class Revision < ActiveRecord::Base
  belongs_to :resource
  belongs_to :permission
  has_many :merged, class_name: 'Revision'

  scope :latest, -> { order('modified_date DESC').first }
  scope :exclude_merged, -> { where(:revision_id => nil).order('modified_date DESC') }

  MERGE_TIME_THRESHOLD = 8.minutes.freeze
  WEAK_THRESHOLD_BASE = 1.freeze # divided with chars_count -> 1/100 = 0.01 = 1%, 1/1000 = 0.001 = 0.1%

  def total_percental_change
    result = percental_change.blank? ? 0.0 : percental_change
    unless merged.nil?
      merged.each do |revision|
        result += revision.percental_change
      end
    end
    return result
  end

  def total_percental_add
    result = percental_add.blank? ? 0.0 : percental_add
    unless merged.nil?
      merged.each do |revision|
        # additive is using absolute value in this case
        result += revision.percental_add.abs
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
    is_weak = (total_percental_change < (weak_threshold)) ? (total_percental_add < (weak_threshold)) : false
    update_attribute(:is_weak, is_weak)
  end

  def previous
    Revision
      .where('resource_id=? AND modified_date < ?', resource_id, modified_date )
      .order('modified_date DESC').first
  end

  def merge_if_weak
    previous = previous()
    # return, if there is no previous revision or it has already been set (due to recursion)
    return if previous.blank? || !revision_id.blank?

    # same modifier + max. X minutes in between revision
    if (permission_id.eql? previous.permission_id) &&
        ((modified_date - MERGE_TIME_THRESHOLD) <= previous.modified_date)
      # previous will be merged with me. latest revision stays
      master_id = revision_id.blank? ? id : revision_id
      previous.update_attribute(:revision_id, master_id)
    end

    # start recursion
    previous.merge_if_weak

    # end recursion
    set_is_weak()
  end

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