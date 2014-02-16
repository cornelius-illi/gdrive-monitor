class ResourcesDatatable
  delegate :params, :link_to, :monitored_resource_resource_path, :number_to_currency, to: :@view

  def initialize(view, monitored_resource)
    @view = view
    @monitored_resource = monitored_resource
  end

  def as_json(options = {})
    {
        sEcho: params[:sEcho].to_i,
        iTotalRecords: fetch_count(),
        iTotalDisplayRecords: fetch_count(true),
        aaData: data
    }
  end

  private

  # :title_with_icon, :created_date, :modified_date, :revision_count, :collaborators_count, :globally
  def data
    resources.map do |resource|
      [
          title_with_icon( shortened_title(resource['title']), resource['id'] ),
          resource['created_date'].to_datetime.to_s(:db),
          resource['modified_date'].to_datetime.to_s(:db),
          resource['revisions'],
          resource['permissions'],
          resource['permission_groups']
      ]
    end
  end

  def shortened_title(title, length = 35)
    title.size > length+5 ? [title[0,length],title[-5,5]].join("...") : title
  end

  def title_with_icon(title, id)
    link = link_to title, monitored_resource_resource_path(@monitored_resource.id, id)
    #object.is_google_filetype? ? "<img src=\"#{object.iconLink}\" width=\"16\" height=\"16\" alt=\"\" title=\"\" />&nbsp;#{link}" : link
  end

  def resources
    @resources ||= fetch_resources
  end

  def fetch_count(showFiltered=false)
    filters = check_for_filters
    @monitored_resource.resources_analysed_total_entries(filters, showFiltered)
  end

  def fetch_resources
    # filter_periods, filter_mimetype
    filters = check_for_filters
    @monitored_resource.resources_analysed( page(), per_page(), filters, sort_column, sort_direction )
  end

  def check_for_filters
    filters = Hash.new
    if params[:sSearch].present? && !params[:sSearch].blank?
      filters[:sSearch] = params[:sSearch]
    end

    if params[:filter_periods].present? && !params[:filter_periods].blank?
      filters[:filter_periods] = params[:filter_periods]
    end

    if params[:filter_mimetype].present? && !params[:filter_mimetype].blank?
      filters[:filter_mimetype] = params[:filter_mimetype]
    end
    filters
  end

  def page
    params[:iDisplayStart].to_i/per_page
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  # :title_with_icon, :created_date, :modified_date, :revision_count, :collaborators_count, :globally
  def sort_column
    columns = %w[resources.title resources.created_date resources.modified_date revisions permissions permission_groups]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end