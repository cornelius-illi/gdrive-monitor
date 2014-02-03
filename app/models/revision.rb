class Revision < ActiveRecord::Base
  belongs_to :resource
  belongs_to :permission

  scope :latest, order('modified_date DESC').first

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
end