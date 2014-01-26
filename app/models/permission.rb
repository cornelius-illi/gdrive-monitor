class Permission < ActiveRecord::Base
  belongs_to :monitored_resource

end