# -*- encoding : UTF-8 -*-
class BillingMod::ExtraOrder < ApplicationRecord
  self.table_name = 'extra_orders'

  belongs_to :owner, polymorphic: true, optional: true

  scope :of_period, -> (period){ where(period: period) }

  def price_w_vat
    self.price * 1.2
  end
end
