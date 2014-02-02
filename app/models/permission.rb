class Permission < ActiveRecord::Base
  belongs_to :monitored_resource

  def title
    return "#{name} (#{domain})"
  end
end