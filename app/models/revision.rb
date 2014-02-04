class Revision < ActiveRecord::Base
  belongs_to :resource
  belongs_to :permission

  scope :latest, -> { order('modified_date DESC').first }

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

  def is_weak?
    return false if (percental_change.blank? || percental_add.blank?)
    (percental_change < 0.01) ? (percental_add < 0.01) : false
  end

  def calculate_diff(again=false)
    # pre-conditions: has to be a google-file-type and local resource has to be available
    return unless (resource.is_google_filetype? || has_local_resource?)

    # do not calculate again, unless requested
    return if (!(percental_change.blank? || percental_add.blank?) && (not again))

    previous = Revision.where('resource_id=? AND modified_date < ?', resource_id, modified_date ).order('modified_date DESC').first
    return if previous.blank? || !previous.has_local_resource?

    # array of lines, to see which lines changes
    seq1 = File.read(local_resource_path)
    seq2 = File.read(previous.local_resource_path)

    line_count_self =  seq1.length
    line_count_previous =  seq2.length

    diff =  Diff::LCS.diff( seq1, seq2 )

    unless diff.length.eql? 0
      change = (diff[0].length/seq2.length.to_f)
      add = ((seq1.length-seq2.length)/seq2.length.to_f)
    else
      change = 0.0
      add = 0.0
    end

    update_attributes(
        :percental_change => change,
        :percental_add => add
    )
  end
end