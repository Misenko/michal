class OneHost
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :HOST, type: Hash

  def data=(data)
    self[:HOST] = data
  end
end
