class PermissionGroup < ActiveRecord::Base
  #include ActiveModel::ForbiddenAttributesProtection

  belongs_to :monitored_resource
  has_and_belongs_to_many :permissions

end