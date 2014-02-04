module DriveFiles
  FIELDS_FILES_GET = 'alternateLink,createdDate,etag,md5Checksum,fileExtension,fileSize,kind,ownerNames,lastModifyingUserName,mimeType,modifiedDate,shared,sharedWithMeDate,title,labels(trashed,viewed)'
  FIELDS_FILES_LIST = 'items(id,' + FIELDS_FILES_GET + ')'
  FIELDS_PERMISSIONS_GET = 'domain,emailAddress,etag,id,kind,name,role,type,value'
  FIELDS_PERMISSIONS_LIST = 'items(' + FIELDS_PERMISSIONS_GET + ')'

  # @todo: refactor: files -> resources

  def self.retrieve_all_root_folders(user_token)
    query = "'root' in parents AND mimeType='application/vnd.google-apps.folder'" # AND sharedWithMe"
    return self.gdrive_api_file_list(query, user_token)
  end
  
  def self.retrieve_all_files_for(gid, user_token)
    query = "'#{gid}' in parents and trashed = false"
    return self.gdrive_api_file_list(query, user_token)
  end
  
  def self.retrieve_file_metadata(gid, user_token)
    return self.gdrive_api_file_get(gid, user_token)
  end
  
  def self.retrieve_file_permissions(gid, user_token)
    return self.gdrive_api_permission_list(gid, user_token)
  end

  def self.retrieve_permission(fileId,permissionId, user_token)
    return self.gdrive_api_permission_get(fileId, permissionId, user_token)
  end

  def self.download(url, user_token)
    return self.gdrive_api_download(url, user_token)
  end
  
  private
  def self.gdrive_api_file_list(query, user_token)
    response = RestClient.get 'https://www.googleapis.com/drive/v2/files', {:params => {
      :key => GOOGLE['client_secret'], 
      :access_token => user_token,
      :q => query,
      :fields => FIELDS_FILES_LIST }}
    response = JSON::parse(response)
    return response["items"]
  end
  
  def self.gdrive_api_file_get(file_id, user_token)
    # an expection could be thrown regarding insufficient permissions ...
    response = RestClient.get "https://www.googleapis.com/drive/v2/files/#{file_id}", {:params => {
      :key => GOOGLE['client_secret'], 
      :access_token => user_token,
      :fields => FIELDS_FILES_GET }}
    response = JSON::parse(response)
    # should return null
  end
  
  def self.gdrive_api_permission_list(file_id, user_token)
    response = RestClient.get "https://www.googleapis.com/drive/v2/files/#{file_id}/permissions", {:params => {
      :key => GOOGLE['client_secret'], 
      :access_token => user_token,
      :fields => FIELDS_PERMISSIONS_LIST }}
      response = JSON::parse(response)
      return response["items"]
  end

  def self.gdrive_api_permission_get(file_id, permission_id, user_token)
    response = RestClient.get "https://www.googleapis.com/drive/v2/files/#{file_id}/permissions/#{permission_id}", {:params => {
        :key => GOOGLE['client_secret'],
        :access_token => user_token,
        :fields => FIELDS_PERMISSIONS_GET }}
    response = JSON::parse(response)
    return response
  end

  def self.gdrive_api_download(url,user_token)
    resource = RestClient::Resource.new(url)
    # can throw -> RestClient::Unauthorized: 401 Unauthorized
    return resource.get( :Authorization => 'Bearer ' + user_token)
  end
end