class PonctualScripts::SubscriptionMicroToPlusMicro < PonctualScripts::PonctualScript
  def self.execute
    new().run
  end

  def self.rollback
    new().rollback
  end

  private


  def execute
    time = Time.now.beginning_of_month + 15.days
    organizations = Organization.where(code: 'JC')
    # organizations = Organization.where('DATE_FORMAT(created_at, "%Y%m%d") >= 20220201')

    params = { subscription_option: 'ido_plus_micro', is_to_apply_now: 1 }

    organizations.each do |organization|
      logger_infos "[MicroPlus] - Organisation : #{organization.code}"
      customers = organization.customers.active_at(time).joins(:subscription).where('subscriptions.current_packages LIKE "%ido_micro%"')

      logger_infos "[MicroPlus] - Customers size: #{customers.size}"

      customers.each do |customer|
        Subscription::Form.new(customer.subscription, requester).submit(params)

        logger_infos "[MicroPlus] - Customer: #{customer.reload.id} - #{customer.subscription.reload.current_packages.to_s}"
      end
    end
  end

  def requester
    User.find_by_email('mina@idocus.com')
  end
end