# -*- encoding : UTF-8 -*-
# Format periods for XLS reporting
class Organization::MonthlyReport
  def initialize(organization_id, customer_ids, time)
    @time = time
    @period = CustomUtils.period_of(@time)
    @customer_ids    = customer_ids
    @organization_id = organization_id
  end


  def execute
    if price_in_cents_w_vat > 0
      [formatted_price, active_customers_size]
    else
      [nil, nil]
    end
  end

  private

  def active_customers_size
    date_end = @time.to_date.end_of_month
    User.where(id: @customer_ids).active_at(date_end).count
  end


  def price_in_cents_w_vat
    BillingMod::Invoice.where(organization_id: @organization_id).of_period(@period).first.try(:amount_in_cents_w_vat).to_f
  end


  def formatted_price
    ('%0.2f' % (price_in_cents_w_vat.round / 100.0)).tr('.', ',')
  end
end
