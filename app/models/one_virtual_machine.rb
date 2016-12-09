class OneVirtualMachine
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :VM, type: Hash

  def data=(data)
    self[:VM] = data
  end
end
