module BillingMod::UserModule
  extend ActiveSupport::Concern

  included do
    has_many :data_flows, class_name: 'BillingMod::DataFlow', dependent: :destroy
    has_many :packages, class_name: 'BillingMod::Package', dependent: :destroy
    has_many :package_simulations, class_name: 'BillingMod::PackageSimulation', dependent: :destroy
    has_many :billings, class_name: 'BillingMod::Billing', as: :owner
    has_many :billing_simulations, class_name: 'BillingMod::BillingSimulation', as: :owner
    has_many :extra_orders, class_name: 'BillingMod::ExtraOrder', as: :owner
  end

  def can_be_billed_at?(period)
    return true if self.organization.try(:invoice_created_customer)

    if self.created_at.strftime('%Y%m').to_i < 202205
      return true
    else
      piece      = nil
      preseizure = self.preseizures.where('DATE_FORMAT(created_at, "%Y%m") <= ?', period).limit(1).first
      if not preseizure
        piece = self.pieces.where('DATE_FORMAT(created_at, "%Y%m") <= ?', period).limit(1).first
      end

      return (preseizure || piece)? true : false
    end
  end

  def activate_simulation
    @p_simulation = true
  end

  def deactivate_simulation
    @p_simulation = false
  end

  def current_flow
    self.flow_of CustomUtils.period_of(Time.now)
  end

  def my_package
    evaluated_packages.where('period <= ?', CustomUtils.period_of(Time.now)).order(period: :desc).limit(1).first
  end

  def next_package
    self.package_of CustomUtils.period_of(1.month.after)
  end

  def is_package?(name)
    begin
      self.my_package.try(:name).to_s == name.to_s || ( self.my_package.respond_to?(name.to_sym) && self.my_package.send(name.to_sym) )
    rescue
      false
    end
  end

  def package_of(period)
    evaluated_packages.of_period(period).first
  end

  def flow_of(period)
    package   = self.package_of(period)

    return nil if not package

    data_flow = self.data_flows.of_period(period).first || BillingMod::DataFlow.new

    data_flow.period = period
    data_flow.user   = self

    if package.excess_duration == 'annual' && !data_flow.persisted?
      max_version  = self.data_flows.select('MAX(period_version) as max_version').first.max_version.to_i
      data_flows   = self.data_flows.version(max_version).order(period: :desc)
      prev_package = evaluated_packages.of_period(data_flows.first.try(:period)).first

      data_flow.period_version = (max_version > 0 && prev_package.try(:name) == package.name && data_flows.count < 12) ? max_version : (max_version + 1)
    end

    data_flow.save

    data_flow
  end

  def total_billing_of(period)
    evaluated_billings.of_period(period).select("SUM(price) as price").first.price.to_f
  end

  def evaluated_billings
    @p_simulation ? self.billing_simulations : self.billings
  end

  def evaluated_packages
    @p_simulation ? self.package_simulations : self.packages
  end
end