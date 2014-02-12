class Resource < ActiveRecord::Base
  belongs_to :monitored_resource
  has_many :jobs, :class_name => "::Delayed::Job", :as => :owner
  has_many :revisions, -> { order('modified_date DESC') }

  scope :google_resources, -> { where("mime_type IN('application/vnd.google-apps.drawing','application/vnd.google-apps.document','application/vnd.google-apps.spreadsheet','application/vnd.google-apps.presentation')") }

  GOOGLE_FOLDER_TYPE = 'application/vnd.google-apps.folder'.freeze
  GOOGLE_FILE_TYPES = %w(
    application/vnd.google-apps.drawing
    application/vnd.google-apps.document
    application/vnd.google-apps.spreadsheet
    application/vnd.google-apps.presentation
  ).freeze

  GOOGLE_FILE_TYPES_DOWNLOAD = {
      'application/vnd.google-apps.presentation' => { :url => 'https://docs.google.com/feeds/download/presentations/Export?id=',
                                                      :types => ['pptx','pdf','txt'], :local_download_type => 'txt',
                                                      :iconLink => 'https://ssl.gstatic.com/docs/doclist/images/icon_11_presentation_list.png' },
      'application/vnd.google-apps.document' => { :url => 'https://docs.google.com/feeds/download/documents/export/Export?id=',
                                                  :types => ['docx','odt','rtf','html','pdf','txt'], :local_download_type => 'txt',
                                                  :iconLink => 'https://ssl.gstatic.com/docs/doclist/images/icon_11_document_list.png' },
      'application/vnd.google-apps.spreadsheet' => { :url => 'https://docs.google.com/feeds/download/spreadsheets/Export?key=',
                                                     :types => ['pdf','ods','xlsx'], :local_download_type => 'xlsx',
                                                     :iconLink => 'https://ssl.gstatic.com/docs/doclist/images/icon_11_spreadsheet_list.png' },
      'application/vnd.google-apps.drawing' => { :url => 'https://docs.google.com/feeds/download/drawings/Export?id=',
                                                 :types => ['pdf','svg', 'jpeg', 'png'], :local_download_type => 'svg',
                                                 :iconLink => 'https://ssl.gstatic.com/docs/doclist/images/icon_11_drawing_list.png' }
  }.freeze

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

  def iconLink
    return nil unless GOOGLE_FILE_TYPES_DOWNLOAD.has_key?(mime_type)
    GOOGLE_FILE_TYPES_DOWNLOAD[mime_type][:iconLink]
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

  def has_latest_revision?
    # @todo: use file_etag in the future as checksum does only apply to non google-file-types
    # select distinct resources.mime_type from resources JOIN revisions ON revisions.resource_id=resources.id WHERE revisions.md5_checksum IS NOT NULL ORDER BY resources.mime_type;
    (md5_checksum.blank? || revisions.blank?) ? false : (md5_checksum.eql? revisions.latest.md5_checksum)
  end

  def calculate_revision_diffs(again=false)
    revisions.each do |revision|
      revision.calculate_diff(again)
    end
  end

  def merge_weak_revisions
    revisions.first.merge_if_weak

    revisions.each do |r|
      r.set_is_weak()
    end
  end

  def find_collaborations
    revisions.first.find_and_create_collaboration

    revisions.each do |r|
      r.set_is_weak()
    end
  end

  def links
    res = { :alternate_link => alternate_link }
    return res unless GOOGLE_FILE_TYPES_DOWNLOAD.has_key?( mime_type )

    GOOGLE_FILE_TYPES_DOWNLOAD[mime_type][:types].each do |type|
      res[type] = "#{GOOGLE_FILE_TYPES_DOWNLOAD[mime_type][:url]}#{gid}&exportFormat=#{type}"
    end
    return res
  end

  # generates the download link for a revision; without revision id -> downloads current
  def download_revision_link(revision=nil)
    return nil unless GOOGLE_FILE_TYPES_DOWNLOAD.has_key?( mime_type )

    revision = revision.blank? ? "" : "&revision=#{revision}"
    return "#{GOOGLE_FILE_TYPES_DOWNLOAD[mime_type][:url]}#{gid}&exportFormat=#{revisions_download_format}#{revision}"
  end

  def revisions_download_format
    return nil unless GOOGLE_FILE_TYPES_DOWNLOAD.has_key?( mime_type )

    GOOGLE_FILE_TYPES_DOWNLOAD[mime_type][:local_download_type]
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

  def download_path
    return "public/resources/r-#{id.to_s}"
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
          .first_or_initialize

        # if permission has just been created, get metadata
        if permission.id.blank?
          perm_metadata = DriveFiles.retrieve_permission(gid,permission.gid, user_token)
          permission.update_attributes(
              :name => perm_metadata['name'],
              :email_address => perm_metadata['emailAddress'],
              :domain => perm_metadata['domain'],
              :role => perm_metadata['role'],
              :perm_type => perm_metadata['type'],
          )
        end

      new_revision.update_metadata(metadata, permission.id)
    end
  end
  handle_asynchronously :retrieve_revisions, :queue => 'revisions', :owner => Proc.new {|o| o}

  def download_revisions(token)
    # pre-condition: revisions should only be downloaded for diffing and diffing only makes sense for text-based resource formats
    return if is_folder? || !is_google_filetype?

    unless File.directory?( download_path )
      FileUtils.mkdir_p( download_path )
    end

    revisions.each do |revision|
      file_path = File.join( download_path, revision.gid) + '.' + revisions_download_format
      # skip, if downloaded before
      next if File.exists?(file_path)

      download_revision(revision.gid,file_path,token)
    end

    # download the current version
    current = "current-#{modified_date.to_time.to_i}.#{revisions_download_format}"
    current_path = File.join( download_path, current)
    unless File.exists?(current_path)
      # delete all files that were previously downloaded as THE current version
      Dir.glob( "#{download_path}/current-*" ).each { |f| File.delete(f) }
      # nil is for current
      download_revision(nil,current_path,token)
    end
  end
  handle_asynchronously :download_revisions, :queue => 'downloads', :owner => Proc.new {|o| o}


  def download_revision(revision,path,token)
    response = DriveFiles.download( download_revision_link(revision), token)
    if response
      File.open(path, "wb") { |f| f.write( response ) }
    end
  end
  handle_asynchronously :download_revision, :queue => 'downloads', :owner => Proc.new {|o| o}
  # *** DELAYED TASKS - END
end