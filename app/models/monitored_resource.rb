class MonitoredResource < ActiveRecord::Base
  has_many :resources, :dependent => :delete_all
  #attr_accessor :head_resource
  #has_one :head_resource, :class_name => "Resource", :foreign_key => "head_resource_id", :dependent => :destroy
  
  def self.find_or_create_by_resource_id_for(res_gid, current_user)
    # resource is not bound to user, can be used several times
    resource = Resource
      .where(:gid => res_gid)
      .where(:user_id => current_user.id)
      .first_or_create
    resource.update_metadata(current_user.token)
    resource.save!
    
    monitored_resource = MonitoredResource
      .where(:gid => res_gid)
      .where(:user_id => current_user.id)
      .where(:head_resource_id => resource.id)
      .first_or_create
  end
  
  def head_resource
    Resource.find( self.head_resource_id )
  end
  
  def head_resource=(resource)
    self.head_resource_id = resource.id
  end
end
