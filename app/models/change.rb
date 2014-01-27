class Change < ActiveRecord::Base
  belongs_to :resource

  def update_metadata(metadata)
    # deleted,file(etag,lastModifyingUserName),fileId,id,modificationDate
    update_attributes(
        :deleted => metadata['deleted'],
        :etag => metadata['file']['etag'],
        :last_modifying_username => metadata['file']['lastModifyingUserName'],
        :change_id => metadata['id'],
        :modification_date => metadata['modificationDate'],
    )
  end
end