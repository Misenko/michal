class OneUser
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :USER, type: Hash

  def data=(data)
    self[:USER] = data
  end
end
