class Software::Acd < ApplicationRecord
  include Interfaces::Software::Configuration

  belongs_to :owner, polymorphic: true

  attr_encrypted :password, random_iv: true

  validates :encrypted_password, symmetric_encryption: true

  #validates_inclusion_of :auto_deliver, in: [-1, 0, 1]

  def configured?
    if owner.is_a?(Organization)
      username.present? && encrypted_password.present?
    else
      code.present?
    end
  end

  def auto_update_accounting_plan?
    is_auto_updating_accounting_plan
  end

  def auto_deliver?
    auto_deliver
  end
end