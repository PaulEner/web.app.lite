# -*- encoding : UTF-8 -*-
class BillingMod::UpdatePremiumCustomers
  def initialize(organization_code)
    @organization_code = organization_code
  end

  def execute(action="update")
    (action == "update") ? update_all_customers : roolback_all_customers
  end

  private

  def update_all_customers
    list_customers = []
    organization   = Organization.find_by_code @organization_code

    organization.customers.active_at(Time.now).each do |customer|
      current_package = customer.package_of(CustomUtils.period_of(Time.now))
      next_package    = customer.package_of(CustomUtils.period_of(1.month.after))

      if current_package
        update_(current_package)

        list_customers << customer.code
      end

      update_(next_package)    if next_package

      BillingMod::PrepareUserBilling.new(customer.reload).execute
    end

    list_customers
  end

  def roolback_all_customers
    list_customers    = []
    organization      = Organization.find_by_code @organization_code
    @active_customers = organization.customers.active_at(Time.now)
    period            = get_last_period_for(organization)

    @active_customers.each do |customer|
      before_premium_package = period > 0 ? customer.package_of(period) : nil

      current_package = customer.my_package
      next if !current_package || current_package.try(:name) != 'ido_premium'

      if before_premium_package
        current_package.name                 = before_premium_package.name
        current_package.preassignment_active = before_premium_package.preassignment_active
        current_package.mail_active          = before_premium_package.mail_active
        current_package.upload_active        = before_premium_package.upload_active
        current_package.bank_active          = before_premium_package.bank_active
        current_package.scan_active          = before_premium_package.scan_active

        current_package.commitment_start_period = before_premium_package.commitment_start_period
        current_package.commitment_end_period   = before_premium_package.commitment_end_period

        current_package.save
      else
        if customer.jefacture_account_id.present?
          current_package.name = 'ido_x'

          current_package.upload_active = false
          current_package.scan_active   = false
          current_package.mail_active   = false
        else
          current_package.name = 'ido_classic'
        end

        current_package.commitment_start_period = 0
        current_package.commitment_end_period   = 0

        current_package.save
      end

      next_package = customer.package_of(CustomUtils.period_of(1.month.after))
      next_package.destroy if next_package

      list_customers << customer.code

      BillingMod::PrepareUserBilling.new(customer.reload).execute
    end

    list_customers
  end

  def update_(package)
    package.name = "ido_premium"

    package.preassignment_active = true
    package.upload_active        = true
    package.bank_active          = true
    package.scan_active          = true

    package.commitment_start_period = 0
    package.commitment_end_period   = 0

    package.save
  end

  def get_last_period_for(organization)
    customer = @active_customers.first
    customer.packages.where.not(name: 'ido_premium').order(period: :desc).first.try(:period).to_i
  end
end