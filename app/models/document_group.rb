class DocumentGroup < ActiveRecord::Base
  # @todo only finds classes within the file
  def self.descendants
    ObjectSpace.each_object(::Class).select {|klass| klass < self }
  end

  def self.batch_create_identical
    query = "SELECT r.title, GROUP_CONCAT(r.id) FROM resources r WHERE monitored_resource_id=4 AND mime_type !='application/vnd.google-apps.folder' GROUP BY r.title HAVING COUNT(r.id) > 1"
  end
end