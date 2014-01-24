module DriveFiles
  FIELDS_FILES_GET = 'alternateLink,createdDate,etag,fileExtension,fileSize,kind,ownerNames,lastModifyingUserName,mimeType,modifiedDate,shared,title'
  FIELDS_FILES_LIST = 'items(id,' + FIELDS_FILES_GET + ')'
  FIELDS_PERMISSIONS_LIST = 'items(domain,emailAddress,etag,id,kind,name,role,type,value)'
  
  def self.retrieve_all_root_folders(user_token)
    query = "'root' in parents and mimeType='application/vnd.google-apps.folder'"
    return self.gdrive_api_file_list(query, user_token)
  end
  
  def self.retrieve_all_files_for(gid, user_token)
    query = "'#{gid}' in parents"
    return self.gdrive_api_file_list(query, user_token)
  end
  
  def self.retrieve_file_metadata(gid, user_token)
    return self.gdrive_api_file_get(gid, user_token)
  end
  
  def self.retrieve_file_permissions(gid, user_token)
    
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
end