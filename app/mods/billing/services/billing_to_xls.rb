# -*- encoding : UTF-8 -*-
class BillingMod::BillingToXls
  def initialize(customers_ids, year, month = 0, with_organization_info = false)
    @year                   = year
    @month                  = month.to_i
    @customers_ids          = customers_ids
    @with_organization_info = with_organization_info
  end

  def execute
    @book = Spreadsheet::Workbook.new

    # Document
    generate_production_datas

    # Invoice
    generate_invoice_datas

    io = StringIO.new('')
    @book.write(io)
    io.string
  end

  private

  def generate_production_datas
    sheet1 = @book.create_worksheet name: 'Production'

    headers = []
    headers << 'Organisation' if @with_organization_info
    headers += [
      'Mois',
      'Année',
      'Code client',
      'Société',
      'Nom du document',
      'Piéces total',
      'Pré-affectation',
      'Opération',
      'Piéces numérisées',
      'Piéces versées',
      'Piéces iDocus\'Box',
      'Piéces automatique',
      'Feuilles numérisées',
      'Pages total',
      'Pages numérisées',
      'Pages versées',
      'Pages iDocus\'Box',
      'Pages automatique',
      'Attache',
      'Hors format'
    ]
    sheet1.row(0).concat headers

    @list       = []

    12.times do |month_ind|
      month_ind += 1
      next if @month > 0 && month_ind != @month

      real_month_ind = (sprintf '%02d', month_ind)

      _period     = "#{@year}#{real_month_ind}".to_i
      _date_end   = Date.parse("#{@year}-#{real_month_ind}-01").to_date.end_of_month

      next if _period > Time.now.strftime('%Y%m').to_i

      @customers = User.where(id: @customers_ids).active_at(_date_end).order(code: :asc)

      all_thread = []

      @customers.each_slice(100) do |user_groups|
        all_thread << Thread.new(user_groups) do |usr_grp|
          usr_grp.each do |user|
            @operations_size   = BillingMod::DataFlow.where(user_id: user.id).of_period(_period).limit(1).select(:operations).first.try(:operations).to_i
            documents          = PeriodDocument.where(user_id: user.id).of_period(_period).order(created_at: :asc, name: :asc).select(:name, :pieces, :preseizures_pieces, :expenses_pieces, :scanned_pieces, :uploaded_pieces, :dematbox_scanned_pieces, :retrieved_pieces, :scanned_sheets, :pages, :scanned_pages, :uploaded_pages, :dematbox_scanned_pages, :retrieved_pages, :paperclips, :oversized)

            if documents.any?
              documents.each do |document|
                fill_data_with(user, month_ind, document)
              end
            else
              fill_data_with(user, month_ind)
            end
          end
        end
      end

      all_thread.each(&:join)
    end

    range = @with_organization_info ? 0..5 : 0..4
    month_index = @with_organization_info ? 1 : 0
    #list = list.sort do |a, b|
    #  _a = a[range]
    #  _b = b[range]
    #  _a[month_index] = ("%02d" % _a[month_index])
    #  _b[month_index] = ("%02d" % _b[month_index])
    #  _a <=> _b
    #end

    @list.each_with_index do |data, index|
      sheet1.row(index + 1).replace(data)
    end
  end

  def generate_invoice_datas
    sheet2 = @book.create_worksheet name: 'Facturation'

    headers = []
    headers << 'Organisation' if @with_organization_info
    headers += [
      'Mois',
      'Année',
      'Code client',
      'Nom du client',
      'Paramètre',
      'Valeur',
      'Prix HT'
    ]
    sheet2.row(0).concat headers

    @list = []

    organizations_id = User.where(id: @customers_ids).distinct.pluck(:organization_id)
    organizations    = Organization.where(id: organizations_id)

    12.times do |month_ind|
      month_ind += 1
      next if @month > 0 && month_ind != @month

      real_month_ind = (sprintf '%02d', month_ind)

      _period     = "#{@year}#{real_month_ind}".to_i
      _date_end   = Date.parse("#{@year}-#{real_month_ind}-01").to_date.end_of_month

      next if _period > Time.now.strftime('%Y%m').to_i

      all_thread = []
      amounts    = 0

      organizations.each do |organization|
        # all_thread << Thread.new do
          last_invoice = organization.invoices.of_period(_period).first
          next if !last_invoice && _period != CustomUtils.period_of(Time.now)

          if last_invoice || _period == CustomUtils.period_of(Time.now)
            organization.billings.of_period(_period).select(:id, :name, :title, :price).each do |billing|
              amounts = amounts.to_f + billing.price.to_f

              data = []
              data << organization.try(:name) if @with_organization_info

              data +=   [
                          month_ind,
                          @year,
                          organization.code,
                          organization.name,
                          billing.title,
                          '',
                          format_price(billing.price)
                        ]
              @list << data
            end
          end

          @customers = User.where(id: @customers_ids, organization_id: organization.id).active_at(_date_end).order(code: :asc)
          @customers.each do |user|
            billings  = BillingMod::Billing.of_period(_period).where(owner_id: user.id, owner_type: 'User').select(:id, :name, :title, :price)
            next if billings.size == 0 

            billings.each do |billing|
              amounts = amounts.to_f + billing.price.to_f

              data = []
              data << user.try(:organization).try(:name) if @with_organization_info

              group_title = BillingMod::Configuration::LISTS[billing.name.to_sym].try(:[], :human_name).presence || billing.title
              title       = group_title != billing.title ? billing.title : ''

              data += [
                        month_ind,
                        @year,
                        user.try(:code).to_s,
                        user.try(:name).to_s,
                        group_title,
                        title,
                        format_price(billing.price)
                      ]

              @list << data
            end
          end
        # end
      end

      # all_thread.each(&:join)

      p "=== Amount : #{amounts.to_f / 100}"
    end

    range = @with_organization_info ? 0..3 : 0..2
    month_index = @with_organization_info ? 1 : 0
    @list = @list.sort do |a, b|
      _a = a[range]
      _b = b[range]
      _a[month_index] = ("%02d" % _a[month_index])
      _b[month_index] = ("%02d" % _b[month_index])
      _a <=> _b
    end

    @list.each_with_index do |data, index|
      sheet2.row(index + 1).replace(data)
    end
  end

  def format_price(price_in_cents)
    ('%0.2f' % (price_in_cents.round / 100.0)).tr('.', ',')
  end

  def fill_data_with(user=nil, month_index=nil, document=nil)
    data = []
    data << user.try(:organization).try(:name) if @with_organization_info
    data += [
              month_index,
              @year,
              user.try(:code),
              user.try(:company),
              document.try(:name),
              document.try(:pieces),
              document.try(:preseizures_pieces).to_i + document.try(:expenses_pieces).to_i,
              @operations_size.to_i,
              document.try(:scanned_pieces).to_i,
              document.try(:uploaded_pieces).to_i,
              document.try(:dematbox_scanned_pieces).to_i,
              document.try(:retrieved_pieces).to_i,
              document.try(:scanned_sheets).to_i,
              document.try(:pages).to_i,
              document.try(:scanned_pages).to_i,
              document.try(:uploaded_pages).to_i,
              document.try(:dematbox_scanned_pages).to_i,
              document.try(:retrieved_pages).to_i,
              document.try(:paperclips).to_i,
              document.try(:oversized).to_i
            ]

    @list << data
  end
end
