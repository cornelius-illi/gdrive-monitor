class ResourcesDatatable
  delegate :params, :link_to, :monitored_resource_resource_path, :number_to_currency, to: :@view

  def initialize(view, monitored_resource)
    @view = view
    @monitored_resource = monitored_resource
  end

  def as_json(options = {})
    {
        sEcho: params[:sEcho].to_i,
        iTotalRecords: @monitored_resource.resources.count,
        iTotalDisplayRecords: resources.total_entries,
        aaData: data
    }
  end

  private

  # :title_with_icon, :created_date, :modified_date, :revision_count, :collaborators_count, :globally
  def data
    resources.map do |resource|
      [
          title_with_icon(resource),
          resource.created_date.to_s(:db),
          resource.modified_date.to_s(:db),
          resource.revisions.length,
          resource.collaborators.length,
          globally(resource)
      ]
    end
  end

  def globally(object)
    globally = object.global_collaboration? ? 'check' : 'x'
    return '<span class="fi-' + globally + '"><span class="hidden">' + globally +'</span></span>'
  end

  def title_with_icon(object)
    link = link_to object.shortened_title, monitored_resource_resource_path(object.monitored_resource_id, object.id)
    object.is_google_filetype? ? "<img src=\"#{object.iconLink}\" width=\"16\" height=\"16\" alt=\"\" title=\"\" />&nbsp;#{link}" : link
  end

  def resources
    @resources ||= fetch_resources
  end

  def fetch_resources
    unless sort_column.nil?
      resources = @monitored_resource.resources.order("#{sort_column} #{sort_direction}")
    else
      resources = @monitored_resource.resources
    end

    resources = resources.page(page).per_page(per_page)
    if params[:sSearch].present?
      resources = resources.where("title like :search", search: "%#{params[:sSearch]}%")
    end
    resources
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  # :title_with_icon, :created_date, :modified_date, :revision_count, :collaborators_count, :globally
  def sort_column
    columns = %w[title created_date modified_date]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end