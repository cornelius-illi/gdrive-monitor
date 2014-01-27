class MonitoredResource < ActiveRecord::Base
  has_many  :resources, :dependent => :delete_all
  has_many  :permissions, :dependent => :delete_all
  has_many  :permission_groups, :dependent => :delete_all
  has_and_belongs_to_many :monitored_periods
  has_many :jobs, :class_name => "::Delayed::Job", :as => :owner

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

  def structure_indexing?
    # @todo: add job type/ title to delayed_jobs to be able to distinguish
    return structure_indexed_at.blank? && (jobs.length > 0)
  end

  def changehistory_indexing?
    # @todo: add job type/ title to delayed_jobs to be able to distinguish
    return changehistory_indexed_at.blank? && (jobs.length > 0)
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


  # *** DELAYED TASKS - START
  def index_structure(user_id, user_token, file_id)
    resources = DriveFiles.retrieve_all_files_for(file_id, user_token)

    resources.each do |metadata|
      new_resource = Resource
        .where(:gid => metadata['id'])
        .where(:monitored_resource_id => id)
        .where(:user_id => user_id)
      .first_or_create

      new_resource.update_metadata(metadata)

      # create new delayed_job, if type is folder
      if new_resource.is_folder?
        index_structure(user_id, user_token, new_resource.gid)
      end

      unless structure_indexing?
        update_attribute :structure_indexed_at, Time.now
      end
    end
  end
  handle_asynchronously :index_structure, :queue => 'index_structure', :owner => Proc.new {|o| o}

  def index_changehistory(link)
    if link.blank?
      # start from the beginning changes.list
    else
      # continue one page
    end

    # @todo: get the changes, filter changes, add change to resources
    # @todo: extract link for next, crate new job
  end
  handle_asynchronously :index_changehistory, :queue => 'index_changehistory', :owner => Proc.new {|o| o}
  # *** DELAYED TASKS - END
end