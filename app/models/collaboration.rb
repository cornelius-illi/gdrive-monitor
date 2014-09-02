class Collaboration
  def self.find(monitored_resource=nil, period=nil,limit_to_global=false)

    resource_ids = self.find_collaborated_resources_until(monitored_resource,period,limit_to_global)

    query = ["SELECT r.id, r.title, r.monitored_resource_id, r.mime_type, MAX(rr.modified_date) as last_modification, COUNT(rr.id) revisions, COUNT(DISTINCT p.id) permissions, COUNT(DISTINCT pgp.permission_group_id) as groups"]
    query.first << " FROM resources r JOIN revisions rr ON rr.resource_id=r.id JOIN permissions p ON rr.permission_id=p.id JOIN permission_groups_permissions pgp ON p.id=pgp.permission_id"

    where = ""

    unless resource_ids.blank?
      where << " WHERE r.id IN (#{resource_ids.join(",")}) "
    end

    unless monitored_resource.blank?
      if where.empty?
        where = " WHERE "
      else
        where << " AND "
      end
      where << "r.monitored_resource_id=?"
      query.push monitored_resource.id
    end

    unless period.blank?
      if where.empty?
        where << " WHERE "
      else
        where << " AND "
      end

      where << '(rr.modified_date >= ? AND rr.modified_date <= ? )'
      query.push period.start_date
      query.push period.end_date
    end

    query.first << where
    query.first << " GROUP BY r.id ORDER BY groups DESC, permissions DESC"

    query_sql = ActiveRecord::Base.send(:sanitize_sql_array, query)
    ActiveRecord::Base.connection.exec_query(query_sql)
  end

  def self.count(monitored_resource=nil, period=nil, limit_to_global=false)
      self.find(monitored_resource, period, limit_to_global).count
  end

  def self.find_collaborated_resources_until(monitored_resource=nil, period=nil,limit_to_global=false)
    query = ["SELECT r.id FROM resources r JOIN revisions rr ON rr.resource_id=r.id JOIN permissions p ON rr.permission_id=p.id JOIN permission_groups_permissions pgp ON p.id=pgp.permission_id"]

    where = ""
    unless monitored_resource.blank?
      where = " WHERE r.monitored_resource_id=?"
      query.push monitored_resource.id
    end

    unless period.blank?
      if where.empty?
        where = " WHERE "
      else
        where << " AND "
      end

      where << ' rr.modified_date <= ?'
      query.push period.end_date
    end

    query.first << where

    # only global collaboration
    if limit_to_global
      query.first << " GROUP BY r.id HAVING COUNT(DISTINCT pgp.permission_group_id) > 1"
    else
      query.first << " GROUP BY r.id HAVING COUNT(DISTINCT p.id) > 1"
    end

    query_sql = ActiveRecord::Base.send(:sanitize_sql_array, query)
    results = ActiveRecord::Base.connection.exec_query(query_sql)
    return results.map {|r| r['id']}
  end

  def self.find_collaborated_resources_and_groups(monitored_resource=nil, period=nil,limit_to_global=false)
    resources = Collaboration.find_collaborated_resources_until(monitored_resource,period,limit_to_global)
    groups = DocumentGroup.find_collaborated_document_groups_until(monitored_resource,period,limit_to_global)

    all = resources.concat(groups)
    all.uniq!
    return all
  end


  # Anzahl der "Aktivitäten" die zur "globlen Collaboration" innerhalb einer Periode beigetragen haben   //* (1-0.5) working_day/(days/100)
  def self.illi_metric(monitored_resource=nil, period=nil)
    return nil if (monitored_resource.blank? || period.blank?)

    sum_weighted_revisions = 0

    collaborated_files = self.find(monitored_resource, period, true)
    collaborated_files.each do |file|
      sum_weighted_revisions += file['revisions'] * (file['permissions'].to_f / file['groups'])
    end

    working_days = Revision.count_workdays_for(monitored_resource.id, period)

    return (sum_weighted_revisions <= 0) ? 0 : (sum_weighted_revisions.to_f / working_days).round(2)
  end
end