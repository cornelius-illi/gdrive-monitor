class MonitoredResource < ActiveRecord::Base
  has_many  :resources, :dependent => :delete_all
  has_many  :permissions, :dependent => :delete_all
  has_many  :permission_groups, :dependent => :delete_all
  has_and_belongs_to_many :monitored_periods

  def structure_indexed?
    # structure_indexed?.nil? || structure_indexed?.empty?
    return !structure_indexed_at.blank?
  end

  def changehistory_indexed?
    return !changehistory_indexed_at.blank?
  end

  def structure_indexing?
    # @todo: check if there is a delayed task of type X for this resource
    return false
  end

  def changehistory_indexing?
    # @todo: check if there is a delayed task of type X for this resource
    return false
  end

  def update_metadata(user_token)
    metadata = DriveFiles.retrieve_file_metadata(self.gid, user_token)
    # important, as changes.list needs a criteria when to stop
    lowest_index_date = GOOGLE['lowest_index_date'].to_datetime

    sharedwithme_date = DateTime.parse( metadata['sharedWithMeDate'] )
    lowest_index_date = sharedwithme_date if (lowest_index_date < sharedwithme_date )
    
    update_attributes(
      :created_date => metadata['createdDate'],
      :modified_date => metadata['modifiedDate'],
      :shared_with_me_date => metadata['sharedWithMeDate'],
      :lowest_index_date => lowest_index_date,
      :etag => metadata['etag'],
      :owner_names => metadata['ownerNames'].join(", "),
      :title => metadata['title']
    )
  end
  
  def update_permissions(user_token)
    permissions = DriveFiles.retrieve_file_permissions(gid, user_token)
    permissions.each do |params|
      permission = Permission
        .where(:monitored_resource_id => id)
        .where(:gid => params['id'])
        .first_or_create

      permission.update_attributes(
          :name => params['name'],
          :email_address => params['emailAddress'],
          :domain => params['domain'],
          :role => params['role'],
          :perm_type => params['type'],
      )
    end
  end
end