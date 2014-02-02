class MonitoredResourceSerializer < ActiveModel::Serializer
  embed :ids, include: true

  attributes :id
  has_many :resources, root: :aaData
end
