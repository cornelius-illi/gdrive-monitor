module DriveChanges
  # see: https://developers.google.com/drive/v2/reference/changes#resource
  FIELDS_CHANGES_LIST = 'items(deleted,file(etag,lastModifyingUserName),fileId,id,modificationDate)'

  def self.retrieve_changes_list(start_change_id="", user_token)
    return self.gdrive_api_changes_list(start_change_id, user_token)
  end

  private
  def self.gdrive_api_changes_list(start_change_id="", user_token)
    # max results set to 100 by default

    par = { :params => {
        :key => GOOGLE['client_secret'],
        :access_token => user_token,
        :fields => FIELDS_CHANGES_LIST
      }
    }

    unless start_change_id.blank?
      par[:params][:startChangeId] = start_change_id
    end

    response = RestClient.get 'https://www.googleapis.com/drive/v2/changes', par
    response = JSON::parse(response)
    return response['items']
  end
end