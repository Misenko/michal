class Statistic
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  resourcify

  field :resource_id, type: String
  field :url, type: String
  field :graphs, type: Array
  field :email, type: String
  field :ready, type: Mongoid::Boolean
  field :periodic, type: Mongoid::Boolean
  field :period, type: String
  field :last_update, type: Time
  field :name, type: String

  belongs_to :user
  has_many :waitings

  index({ resource_id: 1 }, { unique: true })

  validates :resource_id, :presence => true
  validates :ready, :presence => true
end
