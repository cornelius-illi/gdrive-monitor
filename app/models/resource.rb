class Resource < ActiveRecord::Base
  belongs_to :monitored_resource
  has_many :revisions, :order => 'modified_date DESC'
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

  def is_folder?
    return (mime_type.eql? 'application/vnd.google-apps.folder')
  end

  def shortened_title(length = 50)
    title.size > length+5 ? [title[0,length],title[-5,5]].join("...") : title
  end

  def collaborators
    return Revision.select("permission_id")
    .where(:resource_id => id)
    .group("permission_id")
    .count("id").length
  end

  def update_metadata(metadata)
    update_attributes(
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
  
  def retrieve_and_update_metadata(token)
    metadata = DriveFiles.retrieve_metadata_for(gid, token)
    update_metadata(metadata)
  end

  # *** DELAYED TASKS - START

  def retrieve_revisions(user_token)
    revisions = DriveRevisions.retrieve_revisions_list( gid, user_token )

    revisions.each do |metadata|
      new_revision = Revision
        .where(:gid => metadata['id'])
        .where(:resource_id => id)
        .first_or_create

      permission = Permission
        .where(:gid => metadata['lastModifyingUser']['permissionId'] )
        .where(:monitored_resource_id => monitored_resource.id )
        .first_or_create

      new_revision.update_metadata(metadata, permission.id)
    end
  end
  handle_asynchronously :retrieve_revisions, :queue => 'revisions', :owner => Proc.new {|o| o}

  # *** DELAYED TASKS - START
end