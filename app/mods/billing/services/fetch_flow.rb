class BillingMod::FetchFlow
  def self.execute(customers=nil)
    new.execute(customers)
  end

  def initialize(period)
    @period = period || CustomUtils.period_of(Time.now)
    @time   = Date.parse( "#{@period.to_s[0..3]}-#{@period.to_s[4..5]}-15" ).to_date
  end

  def execute(customers=nil)
    _customers = Array(customers).presence || User.where(is_prescriber: false).active_at(@time)

    _customers.each do |customer|
      # next if customer.is_prescriber || !customer.still_active?
      next if customer.is_prescriber

      documents         = customer.period_documents.of_period(@period)

      preseizures       = customer.preseizures.where("DATE_FORMAT(created_at, '%Y%m') = #{@period}")
      preseizures_piece = preseizures.where('piece_id > 0').count
      preseizures_ope   = preseizures.where('operation_id > 0').count

      operations_count  = customer.operations.processed.where("DATE_FORMAT(created_at, '%Y%m') = #{@period}").count
      pieces_count      = documents.sum(&:pieces)
      expences_count    = customer.expenses.where("DATE_FORMAT(created_at, '%Y%m') = #{@period}").count

      scanned_sheets    = documents.sum(&:scanned_sheets)

      data_flow         = customer.flow_of(@period)

      next false if data_flow.nil?

      data_flow.pieces            = pieces_count
      data_flow.operations        = operations_count
      data_flow.compta_pieces     = preseizures_piece + expences_count
      data_flow.compta_operations = preseizures_ope

      data_flow.bank_excess    = bank_excess_of(customer)
      data_flow.journal_excess = journal_excess_of(customer)

      data_flow.scanned_sheets = scanned_sheets

      data_flow.save
    end
  end

  private

  def bank_excess_of(customer)
    bank_authorized = 2
    bank_authorized = 1 if customer.try(:organization).try(:code) == 'ALM'

    bank_ids             = customer.operations.processed.where("DATE_FORMAT(created_at, '%Y%m') = #{@period}").pluck(:bank_account_id).uniq
    excess_bank_accounts = customer.bank_accounts.where("DATE_FORMAT(created_at, '%Y%m') <= #{@period}").where(id: bank_ids).size - bank_authorized

    return (excess_bank_accounts > 0)? excess_bank_accounts : 0
  end

  def journal_excess_of(customer)
    excess_journals_count = customer.account_book_types.count - 5

    return (excess_journals_count > 0)? excess_journals_count : 0
  end

  # def scanned_sheet_of(customer)
  #   customer.temp_documents.where(api_name: 'scan', state: 'bundled').where("DATE_FORMAT(created_at, '%Y%m') = #{@period}").count
  # end

end