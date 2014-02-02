class ResourcesDatatable
  delegate :params, :h, :link_to, :number_to_currency, to: :@view

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
        sEcho: params[:sEcho].to_i,
        iTotalRecords: Resources.count,
        iTotalDisplayRecords: products.total_entries,
        aaData: data
    }
  end

  private

  def data
    resources.map do |resource|
      [
          link_to(resource.name, resource),
          h(resource.category),
          h(resource.released_on.strftime("%B %e, %Y")),
          number_to_currency(resource.price)
      ]
    end
  end

  def resources
    @resources ||= fetch_resources
  end

  def fetch_resources
    resources = Resources.order("#{sort_column} #{sort_direction}")
    resources = resources.page(page).per_page(per_page)
    if params[:sSearch].present?
      resources = resources.where("name like :search or category like :search", search: "%#{params[:sSearch]}%")
    end
    resources
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w[name category released_on price]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end