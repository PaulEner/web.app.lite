module BillingMod::OrganizationModule
  extend ActiveSupport::Concern

  included do
    has_many :billings, class_name: 'BillingMod::Billing', as: :owner
    has_many :billing_simulations, class_name: 'BillingMod::BillingSimulation', as: :owner
    has_many :extra_orders, class_name: 'BillingMod::ExtraOrder', as: :owner
  end

  def activate_simulation
    @p_simulation = true
  end

  def deactivate_simulation
    @p_simulation = false
  end

  def can_be_billed?
    !self.is_test && self.is_active && !self.is_for_admin
  end

  def total_billing_of(period)
    evaluated_billings.of_period(period).select("SUM(price) as price").first.price.to_i
  end

  def evaluated_billings
    @p_simulation ? self.billing_simulations : self.billings
  end
end