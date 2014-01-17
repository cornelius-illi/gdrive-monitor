class Permission < ActiveRecord::Base
  belongs_to :monitored_resource
  
  def self.create_from_collection(permissions, mr_id)
    # no find create, there will be no update
    permissions.each do |permission|
      new_permission = Permission.create(
        :gid => permission['id']
        :name => permission['name'],
        :email_address => permission['emailAddress'],
        :domain => permission['domain'],
        :role => permission['role'],
        :type => permission['type'],
        :monitored_resource_id => mr_id
      )
    end
  end
end