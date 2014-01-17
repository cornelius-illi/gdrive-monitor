class Resource < ActiveRecord::Base
  belongs_to :monitored_resource
  # resource is not bound to user, can be used several times
  
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
  
  def self.update_resource_attributes_for(resource, metadata)
    resource.update_attributes(
        :alternate_link => metadata['alternateLink'],
        :created_date => metadata['createdDate'],
        :etag => metadata['etag'],
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
        :title => metadata['title']
      )
  end
  
  def update_metadata(token)
    metadata = DriveFiles.retrieve_metadata_for(gid, token)
    self.update_resource_attributes_for(self, metadata)
  end
end