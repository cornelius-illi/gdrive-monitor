class ResourcesDatatable
  delegate :params, :link_to, :monitored_resource_resource_path, :number_to_currency, to: :@view

  GOOGLE_FILE_TYPES = %w(
    application/vnd.google-apps.drawing
    application/vnd.google-apps.document
    application/vnd.google-apps.spreadsheet
    application/vnd.google-apps.presentation
  ).freeze

  GOOGLE_FILE_TYPES_DOWNLOAD = {
      'application/vnd.google-apps.presentation' => { :url => 'https://docs.google.com/feeds/download/presentations/Export?id=',
                                                      :types => ['pptx','pdf','txt'], :local_download_type => 'txt',
                                                      :iconLink => 'https://ssl.gstatic.com/docs/doclist/images/icon_11_presentation_list.png' },
      'application/vnd.google-apps.document' => { :url => 'https://docs.google.com/feeds/download/documents/export/Export?id=',
                                                  :types => ['docx','odt','rtf','html','pdf','txt'], :local_download_type => 'txt',
                                                  :iconLink => 'https://ssl.gstatic.com/docs/doclist/images/icon_11_document_list.png' },
      'application/vnd.google-apps.spreadsheet' => { :url => 'https://docs.google.com/feeds/download/spreadsheets/Export?key=',
                                                     :types => ['pdf','ods','xlsx'], :local_download_type => 'xlsx',
                                                     :iconLink => 'https://ssl.gstatic.com/docs/doclist/images/icon_11_spreadsheet_list.png' },
      'application/vnd.google-apps.drawing' => { :url => 'https://docs.google.com/feeds/download/drawings/Export?id=',
                                                 :types => ['pdf','svg', 'jpeg', 'png'], :local_download_type => 'svg',
                                                 :iconLink => 'https://ssl.gstatic.com/docs/doclist/images/icon_11_drawing_list.png' }
  }.freeze

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
          title_with_icon( resource ),
          mark_date( resource['created_date'].to_datetime ),
          resource['modified_date'].to_datetime.to_s(:db),
          resource['revisions'],
          resource['permissions'],
          resource['permission_groups']
      ]
    end
  end

  def mark_date(created_date)
    res = created_date.to_s(:db)
    if !period.empty? && created_date < period[:start_date]
      res = "<span class=\"red\">#{created_date.to_s(:db)}</span>"
    end
    res
  end

  def is_google_filetype?(mime_type)
    return GOOGLE_FILE_TYPES.include?(mime_type)
  end

  def iconLink(mime_type)
    return nil unless GOOGLE_FILE_TYPES_DOWNLOAD.has_key?(mime_type)
    GOOGLE_FILE_TYPES_DOWNLOAD[mime_type][:iconLink]
  end

  def shortened_title(title, length = 40)
    title.size > length+5 ? [title[0,length],title[-5,5]].join("...") : title
  end

  def title_with_icon(resource)
    title = shortened_title(resource['title'])
    link = link_to title, monitored_resource_resource_path(@monitored_resource.id, resource['id'])
    is_google_filetype?(resource['mime_type']) ? "<img src=\"#{iconLink(resource['mime_type'])}\" width=\"16\" height=\"16\" alt=\"\" title=\"\" />&nbsp;#{link}" : link
  end

  def resources
    @resources ||= fetch_resources
  end

  def period
    @period ||= fetch_period
  end

  def fetch_period
    return Hash.new unless params[:filter_periods].present? && !params[:filter_periods].blank?
    period = MonitoredPeriod.find(params[:filter_periods])
    return {:start_date => period.start_date, :end_date => period.end_date }
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