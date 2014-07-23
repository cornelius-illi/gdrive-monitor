class Permission < ActiveRecord::Base
  belongs_to  :monitored_resource
  has_many    :revisions

  def title
    return email_address.blank? ? "#{name}@#{domain}" : email_address
  end

  def title_no_mail
    return title.split('@').first
  end

  def unique_title
    return "-  #{title_no_mail}"
    #return "(##{id}): #{title_no_mail}"
  end

  def title_usage
    "#{title} (#{revisions.length})"
  end
end