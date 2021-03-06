class Comment < ActiveRecord::Base
  belongs_to  :resource
  has_many  :replies, class_name: 'Comment', :foreign_key => 'comment_id'

  def update_metadata(metadata)
    # FIELDS: 'items(author,content,context,createdDate,deleted,modifiedDate,status)'
    author = metadata['author'].is_a?(Hash) ? metadata['author']['displayName'] : ""
    context = metadata['context'].is_a?(Hash) ? metadata['context']['value'] : ""

    update_attributes(
        :author => author,
        :content => metadata['content'],
        :context => context,
        :created_date => metadata['createdDate'],
        :modified_date => metadata['modifiedDate'],
        :deleted => metadata['deleted'],
        :status => metadata['status']
    )
  end

  def update_reply_metadata(metadata)
    # replies(author,content,createdDate,deleted,modifiedDate,verb)
    # verb = The action this reply performed to the parent comment.
    author = metadata['author'].is_a?(Hash) ? metadata['author']['displayName'] : ""

    update_attributes(
        :author => author,
        :content => metadata['content'],
        :created_date => metadata['createdDate'],
        :modified_date => metadata['modifiedDate'],
        :deleted => metadata['deleted'],
        :status => metadata['verb']
    )
  end

  # batch fixes
  def self.update_resource_ids
    query = "SELECT c1.id, c2.id as missing_comment_id, c1.resource_id as resource_id FROM comments c1 JOIN comments c2 on c2.comment_id=c1.id WHERE c2.resource_id IS NULL;"
    result_set = ActiveRecord::Base.connection.exec_query(query)
    result_set.each do |comment|
      Comment.find(comment['missing_comment_id']).update(:resource_id => comment['resource_id'])
    end
  end
end
