class MonitoredResource < ActiveRecord::Base
  has_many  :resources, :dependent => :delete_all
  has_many  :permissions, :dependent => :delete_all
  has_many  :permission_groups, :dependent => :delete_all
  
  def self.find_or_create_by_resource_id_for(res_gid, current_user)    
    monitored_resource = MonitoredResource
      .where(:gid => res_gid)
      .where(:user_id => current_user.id)
      .first_or_create
      
    monitored_resource.update_metadata(current_user.token)
    monitored_resource.update_permissions(current_user.token)     
  end
  
  private
  def update_metadata(user_token)
    metadata = DriveFiles.retrieve_file_metadata(self.gid, user_token)
    self.update_attributes(
      :created_date => metadata['createdDate'],
      :modified_date => metadata['modifiedDate'],
      :shared_with_me_date => metadata['sharedWithMeDate'],
      :etag => metadata['etag'],
      :owner_names => metadata['ownerNames'].join(", "),
      :title => metadata['title']
    )
  end
  
  def update_permissions(user_token)
    permissions = DriveFiles.retrieve_file_permissions(self.gid, user_token)
    Permissions.create_from_collection(permissions, self.gid)
  end
end