class Report::Metrics::ChartMostUsedFileTypes < Report::Metrics::AbstractMetric

  TYPE = 'CHART'

  COLORS = {
    'image/jpeg' => '#FF0000',
    'image/png' => '#800000',
    'image/svg+xml' => '#800080',
    'application/pdf' => '#FFFF00',
    'application/vnd.google-apps.document' => '#00FFFF',
    'application/vnd.google-apps.presentation' => '#0000FF',
    'text/html' => '#8B4513',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => '#00FF00',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation' => '#008000',
    'video/quicktime' => '#FF00FF'
  }.freeze

  def self.title
    return 'Most used mime-types'
  end

  def get_color(mime_type)
    return COLORS.has_key?(mime_type) ? COLORS[mime_type] : '#000000'
  end

  def calculate_for(monitored_resource, period, data=nil)
    sql = 'SELECT resources.mime_type, COUNT(resources.id) as count
      FROM revisions JOIN resources ON revisions.resource_id=resources.id
      WHERE resources.monitored_resource_id=? AND revisions.modified_date > ? AND revisions.modified_date <= ?
      GROUP BY mime_type ORDER BY COUNT(resources.id) DESC LIMIT 4;'

    query  = ActiveRecord::Base.send(:sanitize_sql_array, [sql, monitored_resource.id, period.start_date, period.end_date])
    most_used_mimetypes = ActiveRecord::Base.connection.exec_query(query)

    result_set = Array.new
    sum_four_most_used = 0
    most_used_mimetypes.each do |mime_type|
      result_set << [ mime_type['mime_type'], mime_type['count'], get_color(mime_type['mime_type']) ]
      sum_four_most_used += mime_type['count']
    end

    sql_count_all = 'SELECT COUNT(resources.id) as count FROM revisions JOIN resources ON revisions.resource_id=resources.id
      WHERE resources.monitored_resource_id=? AND revisions.modified_date > ? AND revisions.modified_date <= ?;'
    query_count_all  = ActiveRecord::Base.send(:sanitize_sql_array, [sql_count_all, monitored_resource.id, period.start_date, period.end_date])
    remaining_revisions = ActiveRecord::Base.connection.exec_query(query_count_all)

    remaining_count = (remaining_revisions[0]['count']-sum_four_most_used)

    result_set << [ 'REST', remaining_count, '#C0C0C0' ]

    return result_set
  end


end