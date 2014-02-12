class MonitoredResource < ActiveRecord::Base
  has_many  :resources, -> { where.not(mime_type: GOOGLE_FOLDER_TYPE) }, :dependent => :delete_all
  has_many  :permissions, :dependent => :delete_all
  has_many  :permission_groups, :dependent => :delete_all
  has_and_belongs_to_many :monitored_periods
  has_many :jobs, :class_name => "::Delayed::Job", :as => :owner

  GOOGLE_FOLDER_TYPE = 'application/vnd.google-apps.folder'.freeze

  #def self.jobs
    # to address the STI scenario we use base_class.name.
    # downside: you have to write extra code to filter STI class specific instance.
    #Delayed::Job.find_all_by_owner_type(self.base_class.name)
  #end

  def structure_indexed?
    # structure_indexed?.nil? || structure_indexed?.empty?
    return !structure_indexed_at.blank?
  end

  def changehistory_indexed?
    return !changehistory_indexed_at.blank?
  end

  def mime_count
    mime_count = Hash.new
    mime_types = Resource.select(:mime_type).where(:monitored_resource_id => id).uniq

    mime_types.each do |r|
      mime_count[r.mime_type] = Resource.where(:monitored_resource_id => id, :mime_type => r.mime_type).count
    end

    mime_count
  end

  def update_metadata(user_token)
    metadata = DriveFiles.retrieve_file_metadata(self.gid, user_token)
    # important, as changes.index needs a criteria when to stop
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

    resource_bound_permissions = Permission.where(:monitored_resource_id => id, :domain => nil)
    resource_bound_permissions.each do |permission|
      revision = Revision.select(:resource_id).where(:permission_id => permission.id).first
      resource = Resource.where(:id => revision.resource_id).first
      metadata = DriveFiles.retrieve_permission(resource['gid'], permission.gid, user_token)
      permission.update_attributes(
          :name => metadata['name'],
          :email_address => metadata['emailAddress'],
          :domain => metadata['domain'],
          :role => metadata['role'],
          :perm_type => metadata['type'],
      )
    end
  end


  # *** DELAYED TASKS - START
  def index_structure(user_id, user_token, file_id)
    resources = DriveFiles.retrieve_all_files_for(file_id, user_token)

    resources.each do |metadata|
      # @todo: next if .DS_Store or first char == '.'
      new_resource = Resource
        .where(:gid => metadata['id'])
        .where(:monitored_resource_id => id)
        .where(:user_id => user_id)
      .first_or_create

      new_resource.update_metadata(metadata)

      if new_resource.is_folder? # create new delayed_job, if type is folder
        index_structure(user_id, user_token, new_resource.gid)
      else # get revisions (does not apply for folders, have none)
        # fetch revisions only, if checksum of file changed
        unless new_resource.has_latest_revision?
          new_resource.retrieve_revisions(user_token)
        end
      end
    end
  end
  handle_asynchronously :index_structure, :queue => 'index_structure', :owner => Proc.new {|o| o}

  def index_changehistory(user_token)
    return nil # should not be called currently -> using revisions
    # Changes.index returns results in ascending order (oldest first), results on next page are newer
    start_change_id = largest_change_id.blank? ? "" : largest_change_id
    changes = DriveChanges.retrieve_changes_list(start_change_id, user_token)

    # just for speed-up, no need to check all, if no change of interest
    unless DateTime.parse( changes.last['modificationDate']) < shared_with_me_date
      changes.each do |metadata|
        # speed-up
        next if (DateTime.parse( metadata['modificationDate'] ) < shared_with_me_date)

        # check if resource exists, or change is relevant
        # @todo: CHANGES SHOULD NEVER BE UPDATED INDEPENDENTLY, ALWAYS INDEX STRUCTURE BEFORE
        # @todo: --> BEST: only query changes API, use changes to build and update structure
        resource = Resource.find_by_gid(metadata['fileId'])
        unless resource.nil?
          new_change = Change
          .where(:change_id => metadata['id'])
          .where(:resource_id => resource.id)
          .first_or_create

          new_change.update_metadata(metadata)
        end
      end
    end

    # set new largest_change_id to last retrieved change (assume, that order is correct)
    update_attribute(:largest_change_id, changes.last['id'])
    unless changes.length.eql?(0)
      index_changehistory(user_token)
    end
  end
  handle_asynchronously :index_changehistory, :queue => 'index_changehistory', :owner => Proc.new {|o| o}
  # *** DELAYED TASKS - END
end