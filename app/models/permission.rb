class Permission < ActiveRecord::Base
  belongs_to  :monitored_resource
  has_many    :revisions

  def title
    return email_address.blank? ? "#{name}@#{domain}" : email_address
  end

  def unique_title
    return "(##{id}): #{title}"
  end

  def title_usage
    "#{title} (#{revisions.length})"
  end
end