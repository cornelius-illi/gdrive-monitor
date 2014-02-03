class Resource < ActiveRecord::Base
  belongs_to :monitored_resource
  has_many :jobs, :class_name => "::Delayed::Job", :as => :owner
  has_many :revisions, :order => 'modified_date DESC'

  GOOGLE_FOLDER_TYPE = 'application/vnd.google-apps.folder'.freeze
  GOOGLE_FILE_TYPES = %w(
    application/vnd.google-apps.drawing
    application/vnd.google-apps.document
    application/vnd.google-apps.spreadsheet
    application/vnd.google-apps.presentation
  ).freeze

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

  def is_google_filetype?
    return GOOGLE_FILE_TYPES.include?(mime_type)
  end

  def shortened_title(length = 35)
    st = title.size > length+5 ? [title[0,length],title[-5,5]].join("...") : title
    return is_folder? ? '<span class="fi-folder"></span> ' + st :  st
  end

  def collaborators
    h = Hash.new {|hash, key| hash[key] = 0}
    revisions.each do |r|
      # @todo: what if google data is incomplete?
      next if r.permission.nil? # sometimes google data is only partially available
      h[r.permission_id] += 1
    end
    return h
  end

  def global_collaboration?
    # definition: at least one permission from a different permission group
    perm_group_ids = Array.new
    # @todo: works only for n=2 perm-groups. need to look at n-1 groups
    group = PermissionGroup.where(:monitored_resource_id => monitored_resource_id).first

    # pre-condition
    return false if group.nil?

    group.permissions.each do |perm|
      perm_group_ids << perm.id
    end

    perm_ids = collaborators().keys
    intersection = perm_ids & perm_group_ids
    # two cases are relevant: all match, none matches -> one group did all the work
    return !((intersection).length.eql?(perm_ids.length) || intersection.length.eql?(0))
  end

  def revisions_by_permission_group
    # pre-condition: permissions always belong to distinct groups

    result = Hash.new {|hash, key| hash[key] = 0}
    permissions_mapping = Hash.new
    pgroups = PermissionGroup.where(:monitored_resource_id => monitored_resource_id)

    pgroups.each do |group|
      group.permissions.each do |p|
        permissions_mapping[p.id] = group.id
      end
    end

    revisions.each do |r|
      next if r.permission_id.nil?

      gid = permissions_mapping[r.permission_id]
      result[gid] += 1
    end

    return result
  end

  def update_metadata(metadata)
    update_attributes(
        :alternate_link => metadata['alternateLink'],
        :created_date => metadata['createdDate'],
        :etag => metadata['etag'],
        :md5_checksum => metadata['md5Checksum'],
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
    return if is_folder? # results in: 400 Bad Request

    revisions = DriveRevisions.retrieve_revisions_list( gid, user_token )

    revisions.each do |metadata|
      # sometimes no lastModifyingUser is available, then exclude from stats
      next unless metadata.has_key?('lastModifyingUser')
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