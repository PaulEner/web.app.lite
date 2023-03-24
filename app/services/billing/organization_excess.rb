# -*- encoding : UTF-8 -*-
class Billing::OrganizationExcess
  def initialize(period)
    @period          = period
    @organization    = period.organization
  end

  def execute(hard_process = false)
    return false if not @organization

    reset_quota

    basic_res = get_basic_excess(hard_process)
    micro_res = get_plus_micro_excess(hard_process)

    @period.basic_excess             = basic_res[:excess_compta_pieces]
    @period.basic_total_compta_piece = basic_res[:total_compta_pieces]

    @period.plus_micro_excess             = micro_res[:excess_compta_pieces]
    @period.plus_micro_total_compta_piece = micro_res[:total_compta_pieces]

    @period.save
  end

  private

  def get_basic_excess(hard_process = false)
    result = get_excess_of(:ido_classique, hard_process)
  end

  def get_plus_micro_excess(hard_process = false)
    result = get_excess_of(:ido_plus_micro, hard_process)
  end

  def get_excess_of(package, hard_process=false)
    result = { excess_limit: 0, total_compta_pieces: 0 }

    customers_periods.each do |c_period|
      my_package = c_period.user.my_package
      valid  = (package.to_s == 'ido_classique')? valid_for_basic_quota(c_period) : valid_for_plus_micro_quota(c_period)

      if valid
        Billing::UpdatePeriodData.new(c_period).execute if hard_process

        fill_datas_with c_period.reload
        if my_package.preassignment_active
          result[:excess_limit]        += c_period.max_preseizure_pieces_authorized.to_i
          result[:total_compta_pieces] += c_period.preseizure_pieces.to_i
        end
      end
    end

    final  = { total_compta_pieces: 0, excess_compta_pieces: 0 }
    excess = result[:total_compta_pieces] - result[:excess_limit]

    if excess > 0
      final[:total_compta_pieces]  = result[:total_compta_pieces]
      final[:excess_compta_pieces] = excess
    end

    return final
  end

  def customers_periods
    return @customer_periods if @customer_periods

    time = @period.start_date.beginning_of_month + 15.days
    @customers_periods = Period.where(user_id: @organization.customers.active_at(time.to_date).map(&:id)).where('start_date <= ? AND end_date >= ?', time.to_date, time.to_date)
  end

  def valid_for_basic_quota(period)
    !period.is_package?('ido_plus_micro') && !period.is_package?('ido_micro') && !period.is_package?('ido_nano') && !period.is_package?('ido_mini')
  end

  def valid_for_plus_micro_quota(period)
    period.is_package?('ido_plus_micro')
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