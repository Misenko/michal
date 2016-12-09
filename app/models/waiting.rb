class Waiting
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :graph, type: Integer
  field :serie, type: Integer

  belongs_to :statistic
end
