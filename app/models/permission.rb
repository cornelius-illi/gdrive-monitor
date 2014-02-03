class Permission < ActiveRecord::Base
  belongs_to :monitored_resource

  def title
    return email_address.blank? ? "#{name}@#{domain}" : email_address
  end
end