module DriveFiles
  FIELDS_FILE = 'alternateLink,createdDate,etag,fileExtension,fileSize,kind,ownerNames,lastModifyingUserName,mimeType,modifiedDate,shared,title'
  FIELDS_LIST = 'items(id' + FIELDS_FILE + ')'
  
  def retrieve_all_root_folders(user_token)
    query = "'root' in parents and mimeType='application/vnd.google-apps.folder'"
    return gdrive_api_file_list(query, user_token)
  end
  
  def retrieve_all_files_for(gid, user_token)
    query = "'#{gid}' in parents"
    return gdrive_api_file_list(query, user_token)
    # @todo: and trashed = false --> better monitor all files, but mark state
  end
  
  private
  def gdrive_api_file_list(query, user_token)
    response = RestClient.get 'https://www.googleapis.com/drive/v2/files', {:params => {
      :key => GOOGLE['client_secret'], 
      :access_token => user_token,
      :q => query,
      :fields => FIELDS_LIST }}
    response = JSON::parse(response)
    return response["items"]
  end
  
  def gdrive_api_file_get(file_id, user_token)
    # an expection could be thrown regarding insufficient permissions ...
    response = RestClient.get "https://www.googleapis.com/drive/v2/files/#{file_id}", {:params => {
      :key => GOOGLE['client_secret'], 
      :access_token => user_token,
      :fields => }}
    response = JSON::parse(response)
    # should return null
  end
end