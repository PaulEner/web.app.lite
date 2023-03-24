# -*- encoding : UTF-8 -*-
class BillingPresenter
  def initialize(billing=nil, viewer=nil)
    @billing = billing

    @owner   = @billing.try(:owner)
    @period  = @billing.try(:period)

    @viewer = viewer || @owner
    @viewer = Collaborator.new(@viewer) if @viewer && @viewer.try(:collaborator?)
  end


  def render_json
    hash = { documents: documents_json }
    hash[:options] = options_json if can_display_options?
    hash
  end


  def can_display_options?
    return false if not @viewer

    @viewer.is_admin || (@viewer.is_prescriber && @viewer.customers.include?(@owner)) ||
      (
        @viewer.organization.try(:is_detail_authorized) &&
        (@viewer == @owner || (@viewer.is_guest && @viewer.accounts.include?(@owner)))
      )
  end


  def documents_json
    total = {}
    total[:pages]  = 0
    total[:pieces] = 0
    total[:pre_assignments] = 0

    total[:scanned_pages]  = 0
    total[:scanned_pieces] = 0
    total[:scanned_sheets] = 0

    total[:dematbox_scanned_pages]  = 0
    total[:dematbox_scanned_pieces] = 0

    total[:uploaded_pages]  = 0
    total[:uploaded_pieces] = 0

    total[:retrieved_pages]  = 0
    total[:retrieved_pieces] = 0

    total[:oversized]  = 0
    total[:paperclips] = 0

    lists = []

    documents = @owner? @owner.period_documents.of_period(@period) : []
    documents.each do |document|
      list = {}
      list[:name] = document.name

      begin
        pack = document.pack
        if pack
          list[:historic] = pack.content_historic.each { |h| h[:date] = h[:date].strftime('%d/%m/%Y') }
          list[:link] = Rails.application.routes.url_helpers.documents_path(pack_name: pack.name)

          pre_assignments = document.preseizures_pieces + document.expenses_pieces
          pre_assignments = document.report ? (Pack::Report::Preseizure.unscoped.where(report_id: document.report).where.not(piece_id: nil).count  + document.report.expenses.count) : 0 if pre_assignments == 0
        else
          list[:historic] = ''
          list[:link] = '#'
          pre_assignments = 0
        end
      rescue
        list[:historic] = ''
        list[:link] = '#'
        pre_assignments = 0
      end

      list[:pages]  = document.pages.to_s
      list[:pieces] = document.pieces.to_s
      list[:pre_assignments] = pre_assignments.to_s

      list[:scanned_pages]  = document.scanned_pages.to_s
      list[:scanned_pieces] = document.scanned_pieces.to_s
      list[:scanned_sheets] = document.scanned_sheets.to_s

      list[:dematbox_scanned_pages]  = document.dematbox_scanned_pages.to_s
      list[:dematbox_scanned_pieces] = document.dematbox_scanned_pieces.to_s

      list[:uploaded_pages]  = document.uploaded_pages.to_s
      list[:uploaded_pieces] = document.uploaded_pieces.to_s

      list[:retrieved_pages]  = document.retrieved_pages.to_s
      list[:retrieved_pieces] = document.retrieved_pieces.to_s

      list[:oversized]  = document.oversized.to_s
      list[:paperclips] = document.paperclips.to_s

      if document.report.try(:type)
        if document.report.try(:type) == 'NDF'
          list[:report_id] = document.report.try(:id) || '#'
          list[:report_type] = document.report.try(:type) || ''
        elsif @viewer.is_admin || (@viewer.is_prescriber && @viewer.customers.include?(@owner))
          list[:report_id] = document.report.try(:id) || '#'
          list[:report_type] = document.report.try(:type) || ''
        else
          list[:report_id] = '#'
        end
      else
        list[:report_id] = '#'
      end

      lists << list

      total[:pages]  += document.pages
      total[:pieces] += document.pieces
      total[:pre_assignments] += pre_assignments

      total[:scanned_pages]  += document.scanned_pages
      total[:scanned_pieces] += document.scanned_pieces
      total[:scanned_sheets] += document.scanned_sheets

      total[:dematbox_scanned_pages]  += document.dematbox_scanned_pages
      total[:dematbox_scanned_pieces] += document.dematbox_scanned_pieces

      total[:uploaded_pages]  += document.uploaded_pages
      total[:uploaded_pieces] += document.uploaded_pieces

      total[:retrieved_pages]  += document.retrieved_pages
      total[:retrieved_pieces] += document.retrieved_pieces

      total[:oversized]  += document.oversized
      total[:paperclips] += document.paperclips
    end

    total[:pages]  = total[:pages].to_s
    total[:pieces] = total[:pieces].to_s
    total[:pre_assignments] = total[:pre_assignments].to_s

    total[:scanned_pages]  = total[:scanned_pages].to_s
    total[:scanned_pieces] = total[:scanned_pieces].to_s
    total[:scanned_sheets] = total[:scanned_sheets].to_s

    total[:dematbox_scanned_pages]  = total[:dematbox_scanned_pages].to_s
    total[:dematbox_scanned_pieces] = total[:dematbox_scanned_pieces].to_s

    total[:uploaded_pages]  = total[:uploaded_pages].to_s
    total[:uploaded_pieces] = total[:uploaded_pieces].to_s

    total[:retrieved_pages]  = total[:retrieved_pages].to_s
    total[:retrieved_pieces] = total[:retrieved_pieces].to_s

    total[:oversized]  = total[:oversized].to_s
    total[:paperclips] = total[:paperclips].to_s

    compta_pieces_excess = @owner? @owner.billings.where(name: 'excess_billing', kind: 'excess').first.try(:associated_hash).try(:[], :excess).to_i : 0

    {
      list: lists,
      total: total,
      excess: {
        sheets: 0.to_s,
        oversized: 0.to_s,
        paperclips: 0.to_s,
        compta_pieces: compta_pieces_excess.to_s,
        uploaded_pages: 0.to_s,
        dematbox_scanned_pages: 0.to_s
      },
      delivery: 'wait',
      type: 'billing',
      is_valid_for_quota_organization: (@owner? BillingMod::Configuration::LISTS[@owner.my_package.name.to_sym].try(:[], :cummulative_excess) : false)
    }
  end


  def options_json
    lists = []

    billings = @owner? @owner.billings.of_period(@period) : []

    billings.each do |billing|
      list = {}

      group_title = BillingMod::Configuration::LISTS[billing.name.to_sym].try(:[], :human_name).presence || billing.title
      title       = group_title != billing.title ? billing.title : ''

      list[:title] = title
      list[:price] = format_price billing.price
      list[:group_title] = group_title

      lists << list
    end

    _invoices = []

    if @owner && @owner.organization
      _invoices = @owner.organization.invoices.where(period_v2: @period)

      _invoices = _invoices.map do |invoice|
        { number: invoice.number, link: invoice.cloud_content_object.url }
      end
    end

    excess_compta_pieces = @owner? @owner.billings.where(name: 'excess_billing', kind: 'excess').first.try(:price).to_f : 0
    total_price          = @owner? @owner.total_billing_of(@period) : 0

    {
      list:                          lists,
      excess_uploaded_pages:         format_price(0),
      excess_scan:                   format_price(0),
      excess_dematbox_scanned_pages: format_price(0),
      excess_compta_pieces:          format_price(excess_compta_pieces),
      excess_paperclips:             format_price(0),
      total:                         format_price(total_price),
      invoices:                      _invoices
    }
  end

  private


  def format_price(price_in_cents)
    ('%0.2f' % (price_in_cents / 100.0)).tr('.', ',')
  end
end
