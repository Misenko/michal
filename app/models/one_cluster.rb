class OneCluster
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :CLUSTER, type: Hash

  def data=(data)
    self[:CLUSTER] = data
  end
end
