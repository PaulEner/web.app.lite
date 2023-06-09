class Billing::CreateInvoicePdf
  attr_accessor :data

  class << self
    def for_test(_time=nil, organizations=[])
      test_dir = CustomUtils.mktmpdir('create_invoices', Rails.root.join("files/invoices_pdf"), false);

      file = File.open(test_dir + "/invoices_resume.csv", 'w+');
      file.write("Code;Organisation;Montant facture HT;Montant facture TTC;Dossiers Actifs;iDo'Classique;iDo'Micro;iDo'Nano;iDo'X;Automates;Courrier;Numérisation;Prix forfaits/Options;Remises;Montant remises;Total pièces (Quota organisation);Total opérations (Quota organisation);Total Préaff. (Quota organisation);Préaff. Basic en excès (Quota organisation);Prix Basic excès (Quota organisation);Préaff. Micro en excès (Quota organisation);Prix Micro excès (Quota organisation)\n");
      file.close

      begin
        time = _time.to_date.beginning_of_month + 15.days
      rescue
        time = 1.month.ago.beginning_of_month + 15.days
      end

      if organizations.present?
        organizations.each do |organization|
          generate_invoice_of(organization, nil, time, { notify: false, auto_upload: false, test: true, test_dir: test_dir }) if !organization.is_test && organization.is_active && !organization.is_for_admin
        end
      else
        #FIDC must not be treated here
        Organization.where.not(code: 'FIDC').billed.order(created_at: :asc).each do |organization|
          generate_invoice_of(organization, nil, time, { notify: false, auto_upload: false, test: true, test_dir: test_dir })
        end

        #Generate FIDC invoice at last, which mean EG, FIDC, FBC have already been generated
        Organization.where(code: 'FIDC').billed.order(created_at: :asc).each do |organization|
          generate_invoice_of(organization, nil, time, { notify: false, auto_upload: false, test: true, test_dir: test_dir })
        end
      end

      return test_dir
    end

    def for_all
      #FIDC must not be treated here
      Organization.where.not(code: 'FIDC').billed.order(created_at: :asc).each do |organization|
        generate_invoice_of organization
      end

      #Generate FIDC invoice at last, which mean EG, FIDC, FBC have already been generated
      Organization.where(code: 'FIDC').billed.order(created_at: :asc).each do |organization|
        generate_invoice_of organization
      end

      archive_invoice
    end

    def for(organization_id, invoice_number=nil, _time=nil, _options={})
      organization = Organization.where(id: organization_id).billed.first
      return false unless organization

      generate_invoice_of organization, invoice_number, _time, _options
    end

    #_options : [notify: send notification to admin,
    #            auto_upload: send invoice to ACC%IDO and invoice_settings]
    def generate_invoice_of(organization, invoice_number=nil, _time=nil, _options={})
      p "=================== Generating invoice of #{organization.code} =================="
      options = {}
      options[:notify]      = (_options[:notify] === false)? false : true
      options[:auto_upload] = (_options[:auto_upload] === false)? false : true
      options[:test]        = (_options[:test] === true)? true : false
      options[:test_dir]    = _options[:test_dir].presence
      options[:fetch_periods] = (_options[:fetch_periods] === false)? false : true

      begin
        time = _time.to_date.beginning_of_month + 15.days
      rescue
        time = 1.month.ago.beginning_of_month + 15.days
      end

      organization_period = organization.periods.where('start_date <= ? AND end_date >= ?', time.to_date, time.to_date).first

      return false if organization.addresses.select{ |a| a.is_for_billing }.empty?
      return false if organization_period.nil?
      return false if organization_period.invoices.present? && invoice_number.nil? && !options[:test]
      return false if organization.code == 'TEEO'


      p "=================== Next step =================="

      if not options[:test]
        invoice = if invoice_number.present?
                    BillingMod::Invoice.find_by_number(invoice_number) || BillingMod::Invoice.new(organization_id: organization.id, number: invoice_number)
                  else
                    BillingMod::Invoice.new(organization_id: organization.id)
                  end

        return false if invoice.try(:organization_id) != organization.id
      else
        invoice = FakeObject.new
        invoice.created_at   = Time.now
        invoice.updated_at   = Time.now
        invoice.number       = "#{organization.code}_#{organization.id}"
        invoice.organization = organization
      end

      p "=================== Generating invoice : creation #{invoice.persisted?} ==============="

      customers_periods = Period.where(user_id: organization.customers.active_at(time.to_date).map(&:id)).where('start_date <= ? AND end_date >= ?', time.to_date, time.to_date)

      # NOTE update all period before generating invoices (IF NOT TEST)
      c_time = Time.now.to_date.beginning_of_month + 15.days
      if options[:fetch_periods] && (!options[:test] || (options[:test] && c_time == time))
        p "=================== Fetching periods and datas ==============="

        customers_periods.each do |period|
          Billing::UpdatePeriodData.new(period, time).execute
          Billing::UpdatePeriod.new(period, { time: time }).execute
          print '.'
        end

        # Billing::UpdateOrganizationPeriod.new(organization_period).fetch_all
        Billing::OrganizationExcess.new(organization_period).execute

        #Update discount only for organization and when generating invoice
        Billing::UpdatePeriodPrice.new(organization_period).execute
        Billing::DiscountBilling.update_period(organization_period, time)
      end

      return false if customers_periods.empty? && organization_period.price_in_cents_wo_vat == 0

      puts "Generating invoice for organization : #{organization.name}"
      invoice.period       = organization_period
      invoice.vat_ratio    = organization.subject_to_vat ? 1.2 : 1
      invoice.save if not options[:test]
      print "-> Invoice #{invoice.number}..."

      Billing::CreateInvoicePdf.new(invoice, time, options[:auto_upload], { test: options[:test], test_dir: options[:test_dir] }).execute

      if not options[:test]
        #WORKAROUND: deactivate invoice mailer and notification if needed

        if options[:notify]
          organization.admins.each do |admin|
           Notifications::Notifier.new.create_notification({
             url: Rails.application.routes.url_helpers.organization_invoices_url({organization_id: organization.id}.merge(ActionMailer::Base.default_url_options)),
             user: admin,
             notice_type: 'invoice',
             title: "Nouvelle facture disponible",
             message: "Votre facture pour le mois de #{I18n.l(invoice.period.start_date, format: '%B')} est maintenant disponible."
           }, false)
          end

          InvoiceMailer.delay(queue: :high).notify(invoice)
        end
      end
    end

    def archive_invoice(time = Time.now)
      invoices   = BillingMod::Invoice.where("created_at >= ? AND created_at <= ?", time.beginning_of_month, time.end_of_month)
      return false unless invoices.present?

      invoices_files_path = invoices.map { |e| e.cloud_content_object.path }

      archive_name = "invoices_#{(time - 1.month).strftime('%Y%m')}.zip"

      CustomUtils.mktmpdir('create_invoice') do |dir|
        archive_path = DocumentTools.archive("#{dir}/#{archive_name}", invoices_files_path)

        _archive_invoice      = BillingMod::ArchiveInvoice.new
        _archive_invoice.name = archive_name

        _archive_invoice.cloud_content_object.attach(File.open(archive_path), archive_name) if _archive_invoice.save
      end
    end
  end

  def initialize(invoice, time=nil, auto_upload=true, test_options={})
    @invoice     = invoice
    @time        = time
    @auto_upload = auto_upload
    @is_test     = test_options[:test]

    if @is_test
      @test_dir          = test_options[:test_dir]
      @invoice_test_path = @test_dir + "/#{@invoice.number}.pdf"
      @csv_test_path     = @test_dir + "/invoices_resume.csv"
    end
  end

  def execute
    initialize_data_utilities

    make_invoice_pdf

    invoice_path = "#{Rails.root}/tmp/#{@invoice.number}.pdf"

    # @invoice.content = File.new "#{Rails.root}/tmp/#{@invoice.number}.pdf"
    if @is_test
      organization = @invoice.organization
      org_period   = organization.periods.where('start_date <= ? AND end_date >= ?', @time.to_date, @time.to_date).first
      real_invoice = org_period.invoices.first
      FileUtils.cp invoice_path, @invoice_test_path

      file = File.open(@csv_test_path, 'a+')

      customers           = ''
      subscription_amount = ''
      discount            = ''
      discount_amount     = ''
      excess_basic        = ''
      excess_micro        = ''

      next_data = @data.flatten

      next_data.each_with_index do |line, index|
        line = line.to_s

        if( line.match(/Nombre de dossiers actifs/) )
          customers = line.gsub('Nombre de dossiers actifs :', '').strip
        elsif( line.match(/Forfaits et options iDocus pour/) )
          subscription_amount = next_data[index + 1]
        elsif( line.match(/Autres - Remise/) )
          discount        = line.to_s
          discount_amount = next_data[index + 1].to_s
        elsif( line.match(/dossiers mensuels/) )
          excess_basic = next_data[index + 1]
        elsif( line.match(/dossiers iDo'Micro/) )
          excess_micro = next_data[index + 1]
        end
      end

      ttc_amount  = @invoice.amount_in_cents_w_vat
      ttc_amount  = ((ttc_amount).to_f / 100).to_f.to_s
      ht_amount   = (@invoice.amount_in_cents_w_vat.to_f / @invoice.vat_ratio.to_f).round
      ht_amount   = ((ht_amount).to_f / 100).to_f.to_s

      if real_invoice && @invoice.amount_in_cents_w_vat != real_invoice.amount_in_cents_w_vat
        amt  = (real_invoice.amount_in_cents_w_vat.to_f / 100).to_f.to_s
        diff = ((real_invoice.amount_in_cents_w_vat.to_f - @invoice.amount_in_cents_w_vat.to_f) / 100).to_f.to_s
        ttc_amount = "#{ttc_amount} € - (#{amt}) - [#{diff}]"
      end

      file.write("#{organization.code};#{organization.name};#{ht_amount} €;#{ttc_amount} €;#{customers};#{@basic_package_count};#{@micro_package_count};#{@nano_package_count};#{@idox_package_count};#{@retriever_package_count};#{@mail_package_count};#{@digitize_package_count};#{subscription_amount};#{discount};#{discount_amount};#{org_period.total_pieces};#{org_period.total_operations};#{org_period.compta_pieces};#{org_period.basic_excess};#{excess_basic};#{org_period.plus_micro_excess};#{excess_micro}\n");

      file.close
    else
      @invoice.cloud_content_object.attach(File.open(invoice_path), "#{@invoice.number}.pdf") if @invoice.save
    end

    auto_upload_last_invoice if @auto_upload && @invoice.present? && @invoice.persisted? && !@is_test #WORKAROUND : deactivate auto upload invoices if needed
  end

  def initialize_data_utilities
    time = @time || @invoice.created_at - 1.month
    @data    = []
    @total   = 0
    @months  = I18n.t('date.month_names').map { |e| e.capitalize if e }

    @previous_month = @months[time.month]
    @year  = time.year

    customer_ids = @invoice.organization.customers.active_at(time.to_date).map(&:id)

    periods = Period.where(user_id: customer_ids).where("start_date <= ? AND end_date >= ?", time.to_date, time.to_date)

    @mail_package_count      = 0
    @basic_package_count     = 0
    @idox_package_count      = 0
    @micro_package_count     = 0
    @nano_package_count      = 0
    @mini_package_count      = 0
    @annual_package_count    = 0
    @scan_box_package_count  = 0
    @retriever_package_count = 0
    @digitize_package_count  = 0

    periods.each do |period|
      period.product_option_orders.each do |option|
        case option.name
        when 'basic_package_subscription'
          @basic_package_count += 1
        when 'idox_package_subscription'
          @idox_package_count += 1
        when 'mail_package_subscription'
          @mail_package_count += 1
        when 'dematbox_package_subscription'
          @scan_box_package_count += 1
        when 'retriever_package_subscription'
          @retriever_package_count += 1
        when 'annual_package_subscription'
          @annual_package_count += 1
        when 'micro_package_subscription'
          @micro_package_count += 1
        when 'nano_package_subscription'
          @nano_package_count += 1
        when 'mini_package_subscription'
          @mini_package_count += 1
        when 'digitize_package_subscription'
          @digitize_package_count += 1
        end
      end
    end

    ordered_scanner_count   = @invoice.organization.orders.dematboxes.billed.where("created_at >= ? AND created_at <= ?", time.beginning_of_month, time.end_of_month).count
    ordered_paper_set_count = @invoice.organization.orders.paper_sets.billed.where("created_at >= ? AND created_at <= ?", time.beginning_of_month, time.end_of_month).count

    @total = Billing::PeriodBilling.amount_in_cents_wo_vat(time.month, periods)

    @data = [
      ["Nombre de dossiers actifs : #{periods.count}", ''],
      ['Forfaits et options iDocus pour ' + @previous_month.downcase + ' ' + @year.to_s + ' :', format_price(@total) + " €"]
    ]

    if @micro_package_count > 0
      @data << ["- #{@micro_package_count} forfait#{'s' if @micro_package_count > 1} iDo'Micro", '']
    end

    if @nano_package_count > 0
      @data << ["- #{@nano_package_count} forfait#{'s' if @nano_package_count > 1} iDo'Nano", '']
    end

    if @mini_package_count > 0
      @data << ["- #{@mini_package_count} forfait#{'s' if @mini_package_count > 1} iDo'Mini", '']
    end

    if @basic_package_count > 0
      @data << ["- #{@basic_package_count} forfait#{'s' if @basic_package_count > 1} iDo'Classique", '']
    end

    if @idox_package_count > 0
      @data << ["- #{@idox_package_count} forfait#{'s' if @idox_package_count > 1} iDo'X", '']
    end

    if @mail_package_count > 0
      @data << ["- #{@mail_package_count} option#{'s' if @mail_package_count > 1} Courrier", '']
    end

    if @scan_box_package_count > 0
      @data << ["- #{@scan_box_package_count} forfait#{'s' if @scan_box_package_count > 1} iDo'Box", '']
    end

    if @retriever_package_count > 0
      @data << ["- #{@retriever_package_count} option#{'s' if @retriever_package_count > 1} Automates", '']
    end

    if @annual_package_count > 0
      @data << ["- #{@annual_package_count} forfait#{'s' if @annual_package_count > 1} Pack Annuel", '']
    end

    if ordered_paper_set_count > 0
      @data << ["- #{ordered_paper_set_count} commande#{'s' if ordered_paper_set_count > 1} de kit#{'s' if ordered_paper_set_count > 1}", '']
    end

    if ordered_scanner_count > 0
      @data << ["- #{ordered_scanner_count} commande#{'s' if ordered_scanner_count > 1} de scanner#{'s' if ordered_scanner_count > 1} iDo'Box", '']
    end

    if @digitize_package_count > 0
      @data << ["- #{@digitize_package_count} option#{'s' if @digitize_package_count > 1} Numérisation", '']
    end

    options = begin
                @invoice.organization.subscription.periods.select { |period| period.start_date <= time && period.end_date >= time }
                            .first
                            .product_option_orders
                            .by_position
              rescue
                []
              end

    options.each do |option|
      @data << ["#{option.group_title} - #{option.title}", format_price(option.price_in_cents_wo_vat) + " €"] if @invoice.organization.code != 'FIDC'

      @total += option.price_in_cents_wo_vat
    end

    @address = @invoice.organization.addresses.for_billing.first

    @invoice.amount_in_cents_w_vat = (@total * @invoice.vat_ratio).round
  end

  def auto_upload_last_invoice
    begin
      user = User.find_by_code 'ACC%IDO' # Always send invoice to ACC%IDO customer

      file = File.new @invoice.cloud_content_object.path
      content_file_name = @invoice.cloud_content_object.filename

      uploaded_document = UploadedDocument.new( file, content_file_name, user, 'VT', 1, nil, 'invoice_auto', nil )

      logger_message_content(uploaded_document)

      auto_upload_invoice_setting(file, content_file_name)
    rescue => e
      System::Log.info('auto_upload_invoice', "[#{Time.now}] - [#{@invoice.id}] - [#{@invoice.organization.id}] - Error: #{e.to_s}")
    end
  end

  private

  def make_invoice_pdf
    @pdf.destroy if @pdf

    Prawn::Document.generate("#{Rails.root}/tmp/#{@invoice.number}.pdf", :bottom_margin => 150) do |pdf|
      @pdf = pdf

      @pdf.repeat [1] do
        @pdf.image "#{Rails.root}/app/assets/images/application/bandeau_facture_parrainage.jpg", width: 472, height: 151, align: :center, :at => [35, 10]
      end

      make_header

      make_body(@invoice.organization.name)

      make_footer

      @pdf
    end
  end

  def make_header
    @pdf.font 'Helvetica'
    @pdf.fill_color '49442A'

    @pdf.font_size 8
    @pdf.default_leading 4

    header_data = [
      [
        "IDOCUS\n17, rue Galilée\n75116 Paris.",
        "SAS au capital de 50 000 €\nRCS PARIS: 804 067 726\nTVA FR12804067726",
        "contact@idocus.com\nwww.idocus.com\nTél : 01 84 250 251"
      ]
    ]

    @pdf.table(header_data, width: 540) do
      style(row(0), borders: [:top, :bottom], border_color: 'AFA6A6', text_color: 'AFA6A6')
      style(columns(1), align: :center)
      style(columns(2), align: :right)
    end

    @pdf.move_down 10
    @pdf.image "#{Rails.root}/app/assets/images/logo/big_logo.png", width: 90, height: 30, at: [4, @pdf.cursor]

    @pdf.stroke_color '49442A'
    @pdf.font_size 10
    @pdf.default_leading 5

    formatted_address = [@address.company, @address.first_name + ' ' + @address.last_name, @address.address_1, @address.address_2, @address.zip.to_s + ' ' + @address.city, @address.country]
                        .reject { |a| a.nil? || a.empty? }
                        .join("\n")

    @pdf.bounding_box([262, @pdf.cursor], width: 270) do
      @pdf.text formatted_address, align: :right, style: :bold

      if @invoice.organization.vat_identifier
        @pdf.move_down 7

        @pdf.text "TVA : #{@invoice.organization.vat_identifier}", align: :right, style: :bold
      end
    end

    @pdf.font_size(14) do
      @pdf.move_down 30
      @pdf.text "Facture n° " + @invoice.number.to_s + ' du ' + (@invoice.created_at - 1.month).end_of_month.day.to_s + ' ' + @previous_month + ' ' + (@invoice.created_at - 1.month).year.to_s, align: :left, style: :bold
    end

    @pdf.move_down 14
    @pdf.text "<b>Période concernée :</b> " + @previous_month + ' ' + @year.to_s, align: :left, inline_format: true
  end

  def make_body(organization_name)
    @pdf.move_down 30
    data = [['<b>Forfaits & Prestations</b>', '<b>Prix HT</b>']]
    data +=  @data
    data += [['', '']]

    @pdf.table(data, width: 540, cell_style: { inline_format: true }) do
      style(row(0..-1), borders: [], text_color: '49442A')
      style(row(0), borders: [:bottom])
      style(row(-1), borders: [:bottom])
      style(columns(2), align: :right)
      style(columns(1), align: :right)
    end
  end

  def make_footer
    @pdf.move_down 7
    @pdf.float do
      @pdf.text_box 'Total HT', at: [400, @pdf.cursor], width: 60, align: :right, style: :bold
    end
    @pdf.text_box format_price(@total) + " €", at: [470, @pdf.cursor], width: 66, align: :right
    @pdf.move_down 10
    @pdf.stroke_horizontal_line 470, 540, at: @pdf.cursor

    @pdf.move_down 7
    @pdf.float do
      if @invoice.organization.subject_to_vat
        @pdf.text_box 'TVA (20%)', at: [400, @pdf.cursor], width: 60, align: :right, style: :bold
      else
        @pdf.text_box 'TVA (0%)', at: [400, @pdf.cursor], width: 60, align: :right, style: :bold
      end
    end
    if @invoice.organization.subject_to_vat
      @pdf.text_box format_price(@total * @invoice.vat_ratio - @total) + " €", at: [470, @pdf.cursor], width: 66, align: :right
    else
      @pdf.text_box "0 €", at: [470, @pdf.cursor], width: 66, align: :right
    end
    @pdf.move_down 10
    @pdf.stroke_horizontal_line 470, 540, at: @pdf.cursor

    @pdf.move_down 7
    @pdf.float do
      @pdf.text_box 'Total TTC', at: [400, @pdf.cursor], width: 60, align: :right, style: :bold
    end
    if @invoice.organization.subject_to_vat
      @pdf.text_box format_price(@total * @invoice.vat_ratio) + " €", at: [470, @pdf.cursor], width: 66, align: :right
    else
      @pdf.text_box format_price(@total) + " €", at: [470, @pdf.cursor], width: 66, align: :right
    end
    @pdf.move_down 10
    @pdf.stroke_color '000000'
    @pdf.stroke_horizontal_line 470, 540, at: @pdf.cursor

    # Other information
    @pdf.move_down 13
    @pdf.text "Cette somme sera prélevée sur votre compte le 4 #{@months[@invoice.created_at.month].downcase} #{@invoice.created_at.year}"

    if @invoice.organization.vat_identifier && !@invoice.organization.subject_to_vat
      @pdf.move_down 7
      @pdf.text 'Auto-liquidation par le preneur - Art 283-2 du CGI'
    end

    @pdf.move_down 7
    @pdf.text "<b>Retrouvez le détails de vos consommations dans votre espace client dans le menu \"Mon Reporting\".</b>", align: :center, inline_format: true
  end

  def auto_upload_invoice_setting(file, content_file_name)
    invoice_settings = @invoice.organization.invoice_settings || []

    invoice_settings.each do |invoice_setting|
      next unless invoice_setting.user.try(:my_package).try(:upload_active)

      uploaded_document = UploadedDocument.new( file, content_file_name, invoice_setting.user, invoice_setting.journal_code, 1, nil, 'invoice_setting', nil )
      logger_message_content(uploaded_document)
    end
  end

  def logger_message_content(uploaded_document)
    if uploaded_document.valid?
      System::Log.info('auto_upload_invoice', "[#{Time.now}] - [#{@invoice.id}] - [#{@invoice.organization.id}] - Uploaded")
    else
      System::Log.info('auto_upload_invoice', "[#{Time.now}] - [#{@invoice.id}] - [#{@invoice.organization.id}] - #{uploaded_document.full_error_messages}")
    end
  end

  def format_price price_in_cents
    price_in_euros = price_in_cents.blank? ? "" : price_in_cents.round/100.0
    ("%0.2f" % price_in_euros).gsub(".", ",")
  end
end
