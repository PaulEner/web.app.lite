class PonctualScripts::DeactivateRetrieverOptionCustomers < PonctualScripts::PonctualScript
  def self.execute
    new().run
  end

  private

  def execute
    organization = Organization.find_by_code 'CEN'
    customers    = organization.customers

    customers.each do |user|
      logger_infos "[DeactivateRetrieverOption] - user_code: #{user.try(:my_code) || 'no_user'} - Start"

      @subscription = user.subscription

      next if @subscription.current_packages.nil? || @subscription.current_packages == "" || @subscription.current_packages == [] || @subscription.current_packages == '[""]' || @subscription.current_packages == '[]'

      old_packages = @subscription.current_packages.tr('["\]','   ').tr('"', '').split(',').map { |pack| pack.strip }

      current_packages = old_packages - ['retriever_option']

      @subscription.current_packages = current_packages.uniq
      @subscription.futur_packages   = nil

      is_new  = !@subscription.configured?

      if @subscription.configured? && @subscription.save
        set_prices_and_limits
        set_special_excess_values

        @subscription.set_start_date_and_end_date

        Billing::UpdatePeriod.new(@subscription.current_period, { renew_packages: true }).execute
        Subscription::Evaluate.new(@subscription, requester).execute
        Billing::PeriodBilling.new(@subscription.current_period).fill_past_with_0 if is_new

        destroy_pending_orders_if_needed
      end

      logger_infos "[DeactivateRetrieverOption] - user_code: #{user.try(:my_code) || 'no_user'} - new organization_id: #{user.organization_id} - End"
    end
  end

  def set_prices_and_limits
    excess_data = Subscription::Package.excess_of(@subscription.current_active_package)

    values = {
                max_upload_pages_authorized: excess_data[:pieces][:limit],
                unit_price_of_excess_upload: excess_data[:pieces][:price],

                max_preseizure_pieces_authorized: excess_data[:preassignments][:limit],
                unit_price_of_excess_preseizure: excess_data[:preassignments][:price],

                max_expense_pieces_authorized: excess_data[:preassignments][:limit],
                unit_price_of_excess_expense: excess_data[:preassignments][:price]
              }

    @subscription.update_attributes(values)
  end

  def set_special_excess_values
    if @subscription.is_package?('ido_mini')
      values = {
        max_upload_pages_authorized: 600,
        max_preseizure_pieces_authorized: 300,
        max_expense_pieces_authorized: 300
      }

      @subscription.update_attributes(values)
    end
  end

  def destroy_pending_orders_if_needed
    customer = @subscription.user
    return false unless customer

    unless @subscription.is_package?('mail_option')
      paper_set_orders = customer.orders.paper_sets.pending
      paper_set_orders.each { |order| Order::Destroy.new(order).execute } if paper_set_orders.any?
    end

    unless @subscription.is_package?('scan')
      dematbox_orders = customer.orders.dematboxes.pending
      dematbox_orders.each { |order| Order::Destroy.new(order).execute } if dematbox_orders.any?
    end
  end

  def requester
    collab = User.find_by_email 'mina@idocus.com'
    Collaborator.new collab
  end
end