class TokenType
  include Mongoid::Document
  field :name, type: String
  field :description, type: String

  belongs_to :token

  validates :name, :presence => true
end
