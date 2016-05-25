class Token
  include Mongoid::Document
  field :body, type: String

  has_one :token_type
  embedded_in :user

  validates :body, :presence => true
  validates :token_type, :presence => true
end
