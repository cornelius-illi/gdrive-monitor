class ResourceSerializer < ActiveModel::Serializer
  attributes :title_with_icon, :details, :created_date, :modified_date, :revision_count, :collaborators_count, :globally

  def details
    return '<a href="' + monitored_resource_resource_url(object.monitored_resource_id, object.id) + '" class="fi-magnifying-glass"></a>'
  end

  def created_date
    return object.created_date.to_s(:db)
  end

  def modified_date
    return object.modified_date.to_s(:db)
  end

  def revision_count
    return object.revisions.length
  end

  def collaborators_count
    return object.collaborators.length
  end

  def title_with_icon
    object.is_google_filetype? ? "<img src=\"#{object.iconLink}\" width=\"16\" height=\"16\" alt=\"\" title=\"\" />&nbsp;#{object.shortened_title}" : object.shortened_title
  end

  def globally
    globally = object.global_collaboration? ? 'check' : 'x'
    return '<span class="fi-' + globally + '"><span class="hidden">' + globally +'</span></span>'
  end
end
