class User
  include Mongoid::Document
  rolify

  field :name, type: String
  field :external_id, type: Integer
  field :email, type: String
  field :description, type: String

  embeds_many :tokens
  has_many :statistics, dependent: :delete

  index({ external_id: 1 }, { unique: true })

  validates :name, :presence => true

  def admin?
    roles.where(name: 'admin').count > 0
  end
end
