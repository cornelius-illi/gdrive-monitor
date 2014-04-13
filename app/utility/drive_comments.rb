module DriveComments
  # see: https://developers.google.com/drive/v2/reference/comments
  FIELDS_COMMENTS_LIST = 'items(author,commentId,content,context,createdDate,deleted,modifiedDate,replies(author,content,createdDate,deleted,modifiedDate,replyId,verb),selfLink,status)'

  def self.retrieve_comments_list(file_id, user_token)
    return self.gdrive_api_revisions_list(file_id, user_token)
  end

  private
  def self.gdrive_api_revisions_list(file_id, user_token)
    par = { :params => {
        :key => GOOGLE['client_secret'],
        :access_token => user_token,
        :includeDeleted => 'true',
        :maxResults => 100,
        :fields => FIELDS_COMMENTS_LIST
    }
    }

    response = RestClient.get "https://www.googleapis.com/drive/v2/files/#{file_id}/comments", par
    response = JSON::parse(response)
    return response['items']
  end
end