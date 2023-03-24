class Software::SageGec < ApplicationRecord
  include Interfaces::Software::Configuration

  belongs_to :owner, polymorphic: true

  #validates_inclusion_of :auto_deliver, in: [-1, 0, 1]

  def configured?
    sage_private_api_uuid.present?  
  end

  def auto_update_accounting_plan?
    is_auto_updating_accounting_plan
  end

  def auto_deliver?
    auto_deliver
  end
end