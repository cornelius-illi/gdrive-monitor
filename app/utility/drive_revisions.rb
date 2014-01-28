module DriveRevisions
  # see: https://developers.google.com/drive/v2/reference/revisions#resource
  FIELDS_REVISIONS_LIST = 'items(etag,fileSize,id,lastModifyingUser(permissionId),md5Checksum,modifiedDate)'

  def self.retrieve_revisions_list(file_id, user_token)
    return self.gdrive_api_revisions_list(file_id, user_token)
  end

  private
  def self.gdrive_api_revisions_list(file_id, user_token)
    par = { :params => {
        :key => GOOGLE['client_secret'],
        :access_token => user_token,
        :fields => FIELDS_REVISIONS_LIST
      }
    }

    response = RestClient.get "https://www.googleapis.com/drive/v2/files/#{file_id}/revisions", par
    response = JSON::parse(response)
    return response['items']
  end
end