class OneDatastore
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :DATASTORE, type: Hash

  def data=(data)
    self[:DATASTORE] = data
  end
end
