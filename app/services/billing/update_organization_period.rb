# -*- encoding : UTF-8 -*-
# Updates period with last subscription informations
class Billing::UpdateOrganizationPeriod
  def initialize(period)
    @period          = period
    @subscription    = period.subscription
    @organization    = period.organization
  end

  def fetch_all(soft_process = false)
    return false if !@organization || @period.is_locked?

    set_prices_and_limits

    @period.update_attribute :locked_at, Time.now
    time = @period.start_date.beginning_of_month + 15.days

    @customers_periods = Period.where(user_id: @organization.customers.active_at(time.to_date).map(&:id)).where('start_date <= ? AND end_date >= ?', time.to_date, time.to_date)

    reset_quota
    fill_excess_max_values

    @customers_periods.each do |c_period|
      if c_period.is_valid_for_quota_organization
        Billing::UpdatePeriodData.new(c_period).execute if not soft_process
        fill_datas_with c_period.reload
      end
    end

    @period.update_attribute :locked_at, nil
    @period.save
    Billing::UpdatePeriodPrice.new(@period).execute
  end

  private

  def set_prices_and_limits
    #Set ido_classique price and limits params for organization subscription
    excess_data = Subscription::Package.excess_of(:ido_classique)

    values =  {
                unit_price_of_excess_upload: excess_data[:pieces][:price],
                unit_price_of_excess_preseizure: excess_data[:preassignments][:price],
                unit_price_of_excess_expense: excess_data[:preassignments][:price]
              }

    @subscription.update_attributes(values)
    @period.update_attributes(values)
  end

  def fill_excess_max_values
    @period.max_sheets_authorized               = 0
    @period.max_upload_pages_authorized         = 0
    @period.max_dematbox_scan_pages_authorized  = 0
    @period.max_preseizure_pieces_authorized    = 0
    @period.max_expense_pieces_authorized       = 0
    @period.max_paperclips_authorized           = 0
    @period.max_oversized_authorized            = 0

    @customers_periods.each do |c_period|
      if c_period.is_valid_for_quota_organization
        subscription = c_period.subscription
        my_package   = c_period.user.my_package

        @period.max_sheets_authorized               += c_period.max_sheets_authorized.to_i               if subscription.is_package?('mail_option')
        @period.max_upload_pages_authorized         += c_period.max_upload_pages_authorized.to_i         if subscription.is_package?('ido_classique') || subscription.is_package?('mail_option') || subscription.is_package?('scan_option')
        @period.max_dematbox_scan_pages_authorized  += c_period.max_dematbox_scan_pages_authorized.to_i  if c_period.user.is_dematbox_authorized
        @period.max_preseizure_pieces_authorized    += c_period.max_preseizure_pieces_authorized.to_i    if my_package.preassignment_active
        @period.max_expense_pieces_authorized       += c_period.max_expense_pieces_authorized.to_i       if my_package.preassignment_active
        @period.max_paperclips_authorized           += c_period.max_paperclips_authorized.to_i           if subscription.is_package?('mail_option')
        @period.max_oversized_authorized            += c_period.max_oversized_authorized.to_i            if subscription.is_package?('mail_option')
      end
    end
  end

  def reset_quota
    @period.pages  = 0
    @period.pieces = 0

    @period.oversized  = 0
    @period.paperclips = 0

    @period.retrieved_pages  = 0
    @period.retrieved_pieces = 0

    @period.scanned_pages   = 0
    @period.scanned_pieces  = 0
    @period.scanned_sheets  = 0

    @period.uploaded_pages  = 0
    @period.uploaded_pieces = 0

    @period.dematbox_scanned_pages  = 0
    @period.dematbox_scanned_pieces = 0

    @period.expense_pieces    = 0
    @period.preseizure_pieces = 0
  end


  def fill_datas_with(customer_period)
    @period.pages  += customer_period.pages    || 0
    @period.pieces += customer_period.pieces   || 0

    @period.oversized  += customer_period.oversized  || 0
    @period.paperclips += customer_period.paperclips || 0

    @period.retrieved_pages  += customer_period.retrieved_pages   || 0
    @period.retrieved_pieces += customer_period.retrieved_pieces  || 0

    @period.scanned_pages   += customer_period.scanned_pages  || 0
    @period.scanned_pieces  += customer_period.scanned_pieces || 0
    @period.scanned_sheets  += customer_period.scanned_sheets || 0

    @period.uploaded_pages  += customer_period.uploaded_pages  || 0
    @period.uploaded_pieces += customer_period.uploaded_pieces || 0

    @period.dematbox_scanned_pages  += customer_period.dematbox_scanned_pages  || 0
    @period.dematbox_scanned_pieces += customer_period.dematbox_scanned_pieces || 0

    @period.expense_pieces    += customer_period.expense_pieces    || 0
    @period.preseizure_pieces += customer_period.preseizure_pieces || 0
  end
end