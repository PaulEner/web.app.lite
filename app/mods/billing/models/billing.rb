class BillingMod::Billing < ApplicationRecord
  #IMPORTANT : Billing price is in cent
  self.table_name = 'billings'

  serialize :associated_hash, Hash

  belongs_to :owner, polymorphic: true

  validates_presence_of :period, :name
  validates_inclusion_of :kind, in: ['normal', 'discount', 'excess', 're-sit', 'order', 'extra', 'digitize']

  scope :of_period, ->(period){ where(period: period.to_i) }
  scope :is_frozen, ->{ where(is_frozen: true) }
  scope :is_not_frozen, ->{ where(is_frozen: false) }
end