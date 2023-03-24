class ApiToken < ApplicationRecord
  belongs_to :organization

  before_create :generate

  def generate
    self.token = "sk_prod_" + SecureRandom.hex(32)
  end
end
