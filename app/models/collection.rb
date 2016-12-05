class Collection
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :name, type: String
  field :current, type: String
  field :older, type: Array

  validates :name, :presence => true
  validates :current, :presence => true
end
