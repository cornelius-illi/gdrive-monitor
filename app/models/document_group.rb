class DocumentGroup < ActiveRecord::Base
  has_many :resources

  # @todo only finds classes within the file
  def self.descendants
    ObjectSpace.each_object(::Class).select {|klass| klass < self }
  end

  def find(monitored_resource=nil, period=nil)

  end

  def self.find_resources(monitored_resource=nil, period=nil)
    group_ids = DocumentGroup
      .where(:monitored_resource_id => monitored_resource.id).map {|dg| dg.id}

    query = ["SELECT r.id,r.document_group_id FROM resources r "]
    query.first << "JOIN revisions rr ON r.id=rr.resource_id WHERE "

    unless period.blank?
      query.first << " rr.modified_date  <= ? "
      query.push period.end_date
    end

    query.first << "GROUP BY r.id"

    return Resource
      .joins("revisions")
      .where("document_group_id IN(#{group_ids.join(',')})")
      .where()
  end

  def self.find_collaborated_document_groups_until(monitored_resource=nil, period=nil,limit_to_global=false)
    query = ["SELECT r.document_group_id FROM resources r JOIN revisions rr ON rr.resource_id=r.id JOIN permissions p ON rr.permission_id=p.id JOIN permission_groups_permissions pgp ON p.id=pgp.permission_id"]

    where = ""
    unless monitored_resource.blank?
      where = " WHERE r.monitored_resource_id=? AND document_group_id IS NOT NULL "
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
      query.first << " GROUP BY r.document_group_id HAVING COUNT(DISTINCT pgp.permission_group_id) > 1"
    else
      query.first << " GROUP BY r.document_group_id HAVING COUNT(DISTINCT p.id) > 1"
    end

    query_sql = ActiveRecord::Base.send(:sanitize_sql_array, query)
    results = ActiveRecord::Base.connection.exec_query(query_sql)

    document_group_ids = results.map {|r| r['document_group_id']}
    if document_group_ids.blank?
      return []
    else
      resources = Resource
        .where("resources.document_group_id IN (#{document_group_ids.join(",")})")
        .where(:monitored_resource_id => monitored_resource.id)
      return resources.map {|r| r.id }
    end
  end

  def self.count(monitored_resource=nil)
    self.find(monitored_resource).count
  end

  #def self.batch_create_identical
  #  query = "SELECT r.title, GROUP_CONCAT(r.id) FROM resources r WHERE monitored_resource_id=4 AND mime_type !='application/vnd.google-apps.folder' GROUP BY r.title HAVING COUNT(r.id) > 1"
  #end
end