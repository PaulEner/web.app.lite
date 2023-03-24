# -*- encoding : UTF-8 -*-
module Reporting
  # Update billings information for a Specific Pack
  def self.update_pack(pack)
    remaining_dividers = pack.dividers.size
    time = pack.created_at.localtime

    while remaining_dividers > 0
      _period = CustomUtils.period_of(time.to_date)
      current_dividers = pack.dividers.of_period(time, 1)

      ##TO DO: delete period when everithing is ok
      period = pack.owner.subscription.find_or_create_period(time.to_date)

      if current_dividers.any?
        period_document = PeriodDocument.find_or_create_by_pack(pack, _period, period)

        if period_document
          current_pages = pack.pages.of_period(time, 1)
          period_document.pages  = Pack.count_pages_of current_pages
          period_document.pieces = current_dividers.pieces.count

          period_document.retrieved_pages  = Pack.count_pages_of current_pages.retrieved
          period_document.retrieved_pieces = current_dividers.retrieved.pieces.count

          period_document.scanned_pages  = Pack.count_pages_of current_pages.scanned
          period_document.scanned_pieces = current_dividers.scanned.pieces.count
          period_document.scanned_sheets = current_dividers.scanned.sheets.count

          period_document.uploaded_pages  = Pack.count_pages_of current_pages.uploaded
          period_document.uploaded_pieces = current_dividers.uploaded.pieces.count

          period_document.dematbox_scanned_pages  = Pack.count_pages_of current_pages.dematbox_scanned
          period_document.dematbox_scanned_pieces = current_dividers.dematbox_scanned.pieces.count

          period_document.save

          # Billing::UpdatePeriodData.new(period).execute
          # Billing::UpdatePeriodPrice.new(period).execute
        end

        period.update(delivery_state: 'delivered') if period && period_document.pages - period_document.uploaded_pages > 0
      end

      remaining_dividers -= current_dividers.count
      time += period.try(:duration).try(:month).presence || 1.month
    end

    # current_period = pack.owner.subscription.current_period
    # Billing::UpdatePeriod.new(current_period) if current_period.updated_at < 1.days.ago

    # Billing::UpdateOrganizationPeriod.new(pack.organization.subscription.current_period).fetch_all(true)
    # Billing::OrganizationExcess.new(pack.organization.subscription.current_period).execute(true)
  end

  def self.update_report(report)
    reports = Pack::Report.where(name: report.name, document_id: report.document_id)

    period_document = report.document

    return false if not period_document

    preseizures_pieces = 0
    preseizures_operations = 0
    expenses_pieces = 0

    reports.each do |rep|
      preseizures_pieces     = preseizures_pieces + rep.preseizures.where('piece_id > 0').count
      preseizures_operations = preseizures_operations + rep.preseizures.where('operation_id > 0').count
      expenses_pieces        = expenses_pieces + rep.expenses.count
    end

    period_document.preseizures_pieces     = preseizures_pieces
    period_document.expenses_pieces        = expenses_pieces
    period_document.preseizures_operations = preseizures_operations

    period_document.save
  end

  def self.find_or_create_period_document(pack, period=nil, _period=nil)
    time    = pack.created_at.localtime
    _period = _period.presence || CustomUtils.period_of(time.to_date)
    period_document = PeriodDocument.find_or_create_by_pack(pack, _period, period)
  end
end
