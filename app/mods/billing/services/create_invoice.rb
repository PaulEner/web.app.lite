module BillingMod
  class CreateInvoice
    def self.launch_test(with_output = false, organization_code=[], time=Time.now, version=2)
      organization_code = Array(organization_code)
      organizations = (organization_code.any?)? Organization.where(code: organization_code) : []

      p "=== Test MODE : #{time} - #{version}"
      BillingMod::CreateInvoice.new(time, {is_test: true, version: version, with_output: with_output}).execute(organizations)
    end

    def initialize(_time=nil, options={})
      @time              = _time.presence || 1.month.ago
      @is_test           = options[:is_test] ? true : false
      @with_output       = options[:with_output] ? true : false
      @is_update         = options[:is_update] ? true : false
      @notify            = options[:notify] === false ? false : true
      @auto_upload       = options[:auto_upload] === false ? false : true
      @version           = options[:version].presence || 2

      @period    = CustomUtils.period_of(@time)
    end

    def execute(organizations=nil, force=false)
      p "[Start time] ==== #{Time.now}"
      p "==== TEST MODE ACTIVATED ====" if @is_test

      @organizations = Array(organizations).presence || Organization.billed
      @test_dir = ''
      @force    = force

      @test_dir = CustomUtils.mktmpdir('create_invoice', Rails.root.join('files'), false) if @is_test && @with_output

      @organizations.each do |organization|
        @invoice = organization.invoices.of_period(@period).first

        next if !@force && !organization.can_be_billed?
        next if !@force && organization.code == 'TEEO'
        next if @invoice && !@is_test && !@is_update

        generate_invoice_of(organization)
      end

      p "[End time] ==== #{Time.now}"
      @test_dir.presence || 'No output generated'
    end

    private

    ## THIS IS AN ALTERNATIVE METHODE TO UPLOAD INVOICES MANUALLY (USING A send trigger method)
    def upload_invoices(period = nil, invoices = [])
      @auto_upload = true

      if invoices.present?
        _invoices = Array(invoices)
      else
        _period = period.presence || @period
        _invoices = BillingMod::Invoice.of_period(_period.to_i)
      end

      _invoices.each_with_index do |invoice, index|
        @invoice      = invoice
        @invoice_path = invoice.cloud_content_object.reload.path

        next if not File.exist?(@invoice_path)

        p "Uploading #{index} : #{@invoice.number} / #{@invoice.organization.code}"
        auto_upload_invoice
      end
    end

    ## THIS IS AN ALTERNATIVE METHODE TO SEND INVOICES NOTIFICATIONS MANUALLY (USING A send trigger method)
    def notify_invoices(period = nil, invoices = [])
      @notify = true

      if invoices.present?
        _invoices = Array(invoices)
      else
        @period = period.presence || @period
        _invoices = BillingMod::Invoice.of_period(@period.to_i)
      end

      _invoices.each_with_index do |invoice, index|
        @invoice      = invoice
        @invoice_path = invoice.cloud_content_object.reload.path
        @organization = invoice.organization

        next if !File.exist?(@invoice_path) || !@organization

        p "Notify #{index} : #{@invoice.number} / #{@invoice.organization.code}"
        send_notification
      end
    end

    def generate_invoice_of(organization)
      @organization = organization
      @customers    = organization.customers.active_at(@time)

      @packages_count       = {}
      @total_customers_price = 0

      @customers_excess = { bank_excess_count: 0, bank_excess_price: 0, journal_excess_count: 0, journal_excess_price: 0, excess_billing_count: 0, excess_billing_price: 0 }

      ### WARNING: june_price node is valid only for June billing
      @other_orders = { june_price: 0, discount_price: 0, re_site_price: 0, orders_price: 0, digitize_price: 0, remaining_month_price: 0 }

      recalculate_billing = @force || @is_update || @period == CustomUtils.period_of(Time.now) || !@invoice

      @customers.each do |customer|
        if recalculate_billing
          BillingMod::PrepareUserBilling.new(customer, @period).execute
        end

        package = customer.package_of(@period)

        next if not package
        next if not customer.can_be_billed_at?(@period)

        if @version == 2
          increm_package_count(package.name)    if ['ido_premium', 'ido_classic', 'ido_nano', 'ido_x', 'ido_micro_plus', 'ido_micro'].include?(package.name)
          increm_package_count('ido_digitize')  if package.name == 'ido_digitize' || (package.scan_active && CustomUtils.is_manual_paper_set_order?(@organization) && BillingMod::Configuration::LISTS[package.name.to_sym][:options][:digitize] == 'optional')
          increm_package_count('ido_retriever') if package.name == 'ido_retriever' || (package.bank_active && BillingMod::Configuration::LISTS[package.name.to_sym][:options][:bank] == 'optional')
          increm_package_count('mail')          if package.mail_active && BillingMod::Configuration::LISTS[package.name.to_sym][:options][:mail] == 'optional'
        else
          increm_package_count('iDoPremium')    if package.name == 'ido_premium'
          increm_package_count('iDoClassique')  if package.name == 'ido_classic'
          increm_package_count('iDoNano')       if package.name == 'ido_nano'
          increm_package_count('iDoX')          if package.name == 'ido_x'
          increm_package_count('iDoMicro')      if ['ido_micro_plus', 'ido_micro'].include?(package.name)
          increm_package_count('Numérisation')  if package.name == 'ido_digitize' || (package.scan_active && CustomUtils.is_manual_paper_set_order?(@organization) && BillingMod::Configuration::LISTS[package.name.to_sym][:options][:digitize] == 'optional')
          increm_package_count('Automates')     if package.name == 'ido_retriever' || (package.bank_active && BillingMod::Configuration::LISTS[package.name.to_sym][:options][:bank] == 'optional')
          increm_package_count('Courriers')     if package.mail_active && BillingMod::Configuration::LISTS[package.name.to_sym][:options][:mail] == 'optional'
        end
        @total_customers_price += customer.total_billing_of(@period)

        more_datas_of(customer) if @version == 2
      end

      if recalculate_billing
        BillingMod::PrepareOrganizationBilling.new(@organization, @period).execute(@force)
      end

      return false if ( @total_customers_price + @organization.total_billing_of(@period) ) == 0

      create_invoice
      generate_pdf
      auto_upload_invoice
      send_notification
    end

    def more_datas_of(customer)
      customer.billings.of_period(@period).each do |billing|
        data = billing.associated_hash

        case billing.kind
          when "excess"
            if billing.name == "bank_excess"
              @customers_excess[:bank_excess_count] += data.try(:[], :excess).to_i
              @customers_excess[:bank_excess_price] += billing.price
            elsif billing.name == "journal_excess"
              @customers_excess[:journal_excess_count] += data.try(:[], :excess).to_i
              @customers_excess[:journal_excess_price] += billing.price
            elsif billing.name == "excess_billing"
              @customers_excess[:excess_billing_count] += data.try(:[], :excess).to_i
              @customers_excess[:excess_billing_price] += billing.price
            end
        when "re-sit"
          @other_orders[:re_site_price] += billing.price
        when "digitize"
          @other_orders[:digitize_price] += billing.price
        when "order"
          @other_orders[:orders_price] += billing.price
        when "extra"
          #### CONDITION : only valid for june billing
          if billing.title == 'Rattrapage sur facturation : Mai'
            @other_orders[:june_price] += billing.price
          else
            @other_orders[:orders_price] += billing.price
          end
        when "discount"
          @other_orders[:discount_price] += billing.price
        end

        @other_orders[:remaining_month_price] += billing.price if billing.name == "remaining_month"
      end
    end

    def create_invoice
      if @is_test
        p "========= Creating invoice of : #{@organization.code}_#{@organization.id} ==> #{ @period } "

        @invoice              = FakeObject.new
        @invoice.created_at   = Time.now
        @invoice.updated_at   = Time.now
        @invoice.number       = "#{@organization.code}_#{@organization.id}"
      else
        @invoice            ||= BillingMod::Invoice.new
      end

      @invoice.vat_ratio      = @organization.subject_to_vat ? 1.2 : 1
      @invoice.period_v2      = @period
      @invoice.organization   = @organization

      total = @total_customers_price + @organization.total_billing_of(@period)
      @invoice.amount_in_cents_w_vat = (total * @invoice.vat_ratio).round

      @invoice.save if not @is_test
    end

    def generate_pdf
      if @version == 2
        @invoice_path = BillingMod::PdfGeneratorV2.new(@organization, @packages_count, @invoice, @total_customers_price, @time, @customers_excess, @other_orders).generate
      else
        @invoice_path = BillingMod::PdfGenerator.new(@organization, @packages_count, @invoice, @total_customers_price, @time).generate
      end

      if not @is_test
        @invoice.cloud_content_object.attach(File.open(@invoice_path), File.basename(@invoice_path))
      else
        invoice_test_path = @test_dir.to_s + "/#{@organization.code}_#{@organization.id}.pdf"
        FileUtils.cp @invoice_path, invoice_test_path if @test_dir.present? && @with_output
      end
    end

    def auto_upload_invoice
      if !@is_test && @auto_upload
        return false if @invoice.amount_in_cents_w_vat.to_f == 0

        begin
          user = User.find_by_code 'ACC%IDO' # Always send invoice to ACC%IDO customer

          file = File.new @invoice_path
          content_file_name = @invoice.cloud_content_object.filename

          uploaded_document = UploadedDocument.new( file, content_file_name, user, 'VT', 1, nil, 'invoice_auto', nil )

          auto_upload_invoice_setting(file, content_file_name)
        rescue => e
          System::Log.info('auto_upload_invoice', "[#{Time.now}] - [#{@invoice.id}] - [#{@invoice.organization.id}] - Error: #{e.to_s}")
        end
      else
        p "====== Auto Upload : OFF ========="
      end
    end

    def auto_upload_invoice_setting(file, content_file_name)
      if !@is_test && !@is_update && @auto_upload
        invoice_settings = @invoice.organization.invoice_settings || []

        invoice_settings.each do |invoice_setting|
          next if not invoice_setting.user.authorized_upload?

          uploaded_document = UploadedDocument.new( file, content_file_name, invoice_setting.user, invoice_setting.journal_code, 1, nil, 'invoice_setting', nil )
        end
      end
    end

    def send_notification
      if !@is_test && !@is_update && @notify
        @organization.admins.each do |admin|
         Notifications::Notifier.new.create_notification({
           url: Rails.application.routes.url_helpers.organization_invoices_url({organization_id: @organization.id}.merge(ActionMailer::Base.default_url_options)),
           user: admin,
           notice_type: 'invoice',
           title: "Nouvelle facture disponible",
           message: "Votre facture pour la période de #{@period} est maintenant disponible."
         }, false)
        end

        InvoiceMailer.delay(queue: :high).notify(@invoice)
      else
        p "====== Send Notification : OFF ========="
      end
    end

    def increm_package_count(package_name)
      package_name = 'ido_micro' if @version == 2 && package_name == 'ido_micro_plus'

      begin
        @packages_count[package_name] += 1
      rescue
        @packages_count[package_name] = 1
      end
    end
  end

  class PdfGenerator
    def initialize(organization, packages_count, invoice, total_customers_price, time)
      @organization          = organization
      @packages_count        = packages_count
      @invoice               = invoice
      @total_customers_price = total_customers_price
      @time                  = time
      @period                = CustomUtils.period_of(@time)

      @months                = I18n.t('date.month_names').map { |e| e.capitalize if e }
      @period_month          = @months[time.month]
      @year                  = time.year
    end

    def generate
      @pdf.destroy if @pdf

      invoice_path = "#{Rails.root}/tmp/#{@invoice.number}.pdf"

      Prawn::Document.generate(invoice_path, :bottom_margin => 150) do |pdf|
        @pdf = pdf

        @pdf.repeat [1] do
          @pdf.image "#{Rails.root}/app/assets/images/application/bandeau_dematbox.jpg", width: 472, height: 220, align: :center, :at => [35, 70]
        end

        make_header

        make_body

        make_footer

        @pdf
      end

      invoice_path
    end

    private

    def make_header
      address = @organization.addresses.for_billing.first
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

      formatted_address = [address.company, address.first_name + ' ' + address.last_name, address.address_1, address.address_2, address.zip.to_s + ' ' + address.city, address.country]
                          .reject { |a| a.nil? || a.empty? }
                          .join("\n")

      @pdf.bounding_box([262, @pdf.cursor], width: 270) do
        @pdf.text formatted_address, align: :right, style: :bold

        if @organization.vat_identifier
          @pdf.move_down 7

          @pdf.text "TVA : #{@organization.vat_identifier}", align: :right, style: :bold
        end
      end

      @pdf.font_size(14) do
        @pdf.move_down 30
        @pdf.text "Facture n° " + @invoice.number.to_s + ' du ' + (@invoice.created_at - 1.month).end_of_month.day.to_s + ' ' + @period_month + ' ' + (@invoice.created_at - 1.month).year.to_s, align: :left, style: :bold
      end

      @pdf.move_down 14
      @pdf.text "<b>Période concernée :</b> " + @period_month + ' ' + @year.to_s, align: :left, inline_format: true
    end

    def make_body
      @pdf.move_down 30
      data = [['<b>Forfaits & Prestations</b>', '<b>Prix HT</b>']]

      data << ["Nombre de dossiers actifs : #{@organization.customers.active_at(@time).count}", '']
      data << ['Forfaits et options iDocus pour ' + @period_month.downcase + ' ' + @year.to_s + ' :', CustomUtils.format_price(@total_customers_price) + " €"]
      

      @packages_count.sort_by{|k, v| v}.reverse.each do |package|
        if %w(Numérisation Automates Courriers).include?(package[0].to_s)
          data << ["- #{package[1]} option#{'s' if package[1] > 1} #{package[0]}", ""]
        else
          data << ["- #{package[1]} forfait#{'s' if package[1] > 1} #{package[0]}", ""]
        end
      end

      @organization.billings.of_period(@period).each do |billing|
        data << ["#{billing.title}", "#{CustomUtils.format_price(billing.price)} €"]
      end

      data << ['', '']

      @pdf.table(data, width: 540, cell_style: { inline_format: true }) do
        style(row(0..-1), borders: [], text_color: '49442A')
        style(row(0), borders: [:bottom])
        style(row(-1), borders: [:bottom])
        style(columns(2), align: :right)
        style(columns(1), align: :right)
      end
    end

    def make_footer
      total = @total_customers_price + @organization.total_billing_of(@period)
      vat_text    = '0%'
      total_w_vat = total

      if @invoice.organization.subject_to_vat
        vat_text    = '20%'
        total_w_vat = total * @invoice.vat_ratio
      end

      @pdf.move_down 7
      @pdf.float do
        @pdf.text_box 'Total HT', at: [400, @pdf.cursor], width: 60, align: :right, style: :bold
      end
      @pdf.text_box CustomUtils.format_price(total) + " €", at: [470, @pdf.cursor], width: 66, align: :right
      @pdf.move_down 10
      @pdf.stroke_horizontal_line 470, 540, at: @pdf.cursor

      @pdf.move_down 7
      @pdf.float do
        @pdf.text_box "TVA (#{vat_text})", at: [400, @pdf.cursor], width: 60, align: :right, style: :bold
      end

      @pdf.text_box CustomUtils.format_price(total_w_vat - total) + " €", at: [470, @pdf.cursor], width: 66, align: :right
      @pdf.move_down 10
      @pdf.stroke_horizontal_line 470, 540, at: @pdf.cursor

      @pdf.move_down 7
      @pdf.float do
        @pdf.text_box 'Total TTC', at: [400, @pdf.cursor], width: 60, align: :right, style: :bold
      end

      @pdf.text_box CustomUtils.format_price(total_w_vat) + " €", at: [470, @pdf.cursor], width: 66, align: :right
      @pdf.move_down 10
      @pdf.stroke_color '000000'
      @pdf.stroke_horizontal_line 470, 540, at: @pdf.cursor

      # Other information
      @pdf.move_down 13
      @pdf.text "Cette somme sera prélevée sur votre compte le 4 #{@months[@invoice.created_at.month].downcase} #{@invoice.created_at.year}"

      if @invoice.organization.vat_identifier && !@invoice.organization.subject_to_vat
        @pdf.move_down 7
        @pdf.text 'Auto-liquidation par le preneur - Art 283-2 du CGI'
      elsif !@invoice.organization.vat_identifier && !@invoice.organization.subject_to_vat
        @pdf.move_down 7
        @pdf.text 'Exonération de TVA - Art 262-I du CGI'
      end

      @pdf.move_down 7
      @pdf.text "<b>Retrouvez le détails de vos consommations dans votre espace client dans le menu \"Mon Reporting\".</b>", align: :center, inline_format: true
    end
  end

  class PdfGeneratorV2
    def initialize(organization, packages_count, invoice, total_customers_price, time, customers_excess, other_orders)
      @organization          = organization
      @packages_count        = packages_count
      @customers_excess      = customers_excess
      @other_orders          = other_orders
      @invoice               = invoice
      @total_customers_price = total_customers_price
      @time                  = time
      @period                = CustomUtils.period_of(@time)

      @months                = I18n.t('date.month_names').map { |e| e.capitalize if e }
      @period_month          = @months[time.month]
      @year                  = time.year
    end

    def generate
      @pdf.destroy if @pdf

      invoice_path = "#{Rails.root}/tmp/#{@invoice.number}.pdf"

      Prawn::Document.generate(invoice_path, :bottom_margin => 150) do |pdf|
        @pdf = pdf

        @pdf.repeat [1] do
          @pdf.image "#{Rails.root}/app/assets/images/application/bandeau_new_customer.jpg", width: 300, height: 90, :at => [116, 0]
        end

        make_header

        make_body

        make_footer

        @pdf
      end

      invoice_path
    end

    private

    def make_header
      address = @organization.addresses.for_billing.first

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

      formatted_address = [address.company, address.first_name + ' ' + address.last_name, address.address_1, address.address_2, address.zip.to_s + ' ' + address.city, address.country]
                          .reject { |a| a.nil? || a.empty? }
                          .join("\n")

      @pdf.bounding_box([262, @pdf.cursor], width: 270) do
        @pdf.text formatted_address, align: :right, style: :bold

        if @organization.vat_identifier
          @pdf.move_down 7

          @pdf.text "TVA : #{@organization.vat_identifier}", align: :right, style: :bold
        end
      end

      @pdf.font_size(14) do
        @pdf.move_down 10
        @pdf.text "Facture n° " + @invoice.number.to_s + ' du ' + (@invoice.created_at - 1.month).end_of_month.day.to_s + ' ' + @period_month + ' ' + (@invoice.created_at - 1.month).year.to_s, align: :left, style: :bold
      end

      @pdf.move_down 2
      @pdf.text "<b>Période concernée :</b> " + @period_month + ' ' + @year.to_s, align: :left, inline_format: true
    end

    def make_body
      @pdf.move_down 10

      @total_data_test = 0

      data = [['<b>Forfaits & Prestations</b>', '<b>Prix HT</b>']]

      data << ["Nombre de dossiers actifs : #{@organization.customers.active_at(@time).count}", '']

      @packages_count.sort_by{|k, v| v}.reverse.each do |package|
        if %w(ido_digitize ido_retriever mail).include?(package[0].to_s)
          data << ["- #{package[1]} option#{'s' if package[1] > 1} #{get_human_name_of(package[0])}", "#{CustomUtils.format_price(package[1] * get_price_of(package[0]) * 100)} €"]
        else
          data << ["- #{package[1]} forfait#{'s' if package[1] > 1} #{get_human_name_of(package[0])}", "#{CustomUtils.format_price(package[1] * get_price_of(package[0]) * 100)} €"] if package[0].to_s != 'ido_premium'
        end

        @total_data_test += (package[1] * get_price_of(package[0])).to_f
      end

      @other_orders.each do |order|
        data << ["Autre : Dossiers non facturés en Mai", "#{CustomUtils.format_price(order[1])} €"] if order[0].to_s == "june_price" && order[1] != 0
        data << ["Remise sur pré-affectation", "#{CustomUtils.format_price(order[1])} €"] if order[0].to_s == "discount_price" && order[1] != 0
        data << ["Rattrapage : Opérations antérieures", "#{CustomUtils.format_price(order[1])} €"]     if order[0].to_s == "re_site_price" && order[1] != 0
        data << ["Commandes et frais divers", "#{CustomUtils.format_price(order[1])} €"]  if order[0].to_s == "orders_price" && order[1] != 0
        data << ["Numérisation", "#{CustomUtils.format_price(order[1])} €"]               if order[0].to_s == "digitize_price" && order[1] != 0
        data << ["Dossiers avec engagement cloturés", "#{CustomUtils.format_price(order[1])} €"] if order[0].to_s == "remaining_month_price" && order[1] != 0

        @total_data_test += CustomUtils.format_price(order[1]).to_f
      end

      data << ['', '']

      @pdf.default_leading 0
      if @customers_excess[:bank_excess_count] == 0 && @customers_excess[:journal_excess_count] == 0 && @customers_excess[:excess_billing_count] == 0 && @organization.billings.of_period(@period).size == 0
        @pdf.table(data, width: 540, cell_style: { size: 8, inline_format: true, :padding => [5, 1, 1, 1] }) do
          @pdf.default_leading 0
          style(row(0..-1), borders: [], text_color: '49442A')
          style(row(0), borders: [:bottom])
          style(row(-1), borders: [:bottom])
          style(columns(2), align: :right)
          style(columns(1), align: :right)
        end
      else
        @pdf.table(data, width: 540, cell_style: { size: 8, inline_format: true, :padding => [5, 1, 1, 1] }) do
          @pdf.default_leading 0
          style(row(0..-1), borders: [], text_color: '49442A')
          style(row(0), borders: [:bottom])
          style(columns(2), align: :right)
          style(columns(1), align: :right)
        end
      end

      if @customers_excess[:bank_excess_count] > 0 || @customers_excess[:journal_excess_count] > 0 || @customers_excess[:excess_billing_count] > 0
        data = [['<b>Dépassements</b>', '']]

        data << ["Pré-affectations : #{@customers_excess[:excess_billing_count]}", "#{CustomUtils.format_price(@customers_excess[:excess_billing_price])} €"]    if @customers_excess[:excess_billing_count] > 0
        data << ["Journaux Comptables : #{@customers_excess[:journal_excess_count]}", "#{CustomUtils.format_price(@customers_excess[:journal_excess_price])} €"]  if @customers_excess[:journal_excess_count] > 0
        data << ["Banques : #{@customers_excess[:bank_excess_count]}", "#{CustomUtils.format_price(@customers_excess[:bank_excess_price])} €"]         if @customers_excess[:bank_excess_count] > 0

        data << ['', '']

        @total_data_test += CustomUtils.format_price(@customers_excess[:excess_billing_price]).to_f
        @total_data_test += CustomUtils.format_price(@customers_excess[:journal_excess_price]).to_f
        @total_data_test += CustomUtils.format_price(@customers_excess[:bank_excess_price]).to_f

        if @organization.billings.of_period(@period).size == 0
          @pdf.table(data, width: 540, cell_style: { size: 8, inline_format: true, :padding => [4, 1, 1, 1] }) do
            @pdf.default_leading 0
            style(row(0..-1), borders: [], text_color: '49442A')
            style(row(0), borders: [:bottom])
            style(row(-1), borders: [:bottom])
            style(columns(2), align: :right)
            style(columns(1), align: :right)
          end
        else
          @pdf.table(data, width: 540, cell_style: { size: 8, inline_format: true, :padding => [4, 1, 1, 1] }) do
            @pdf.default_leading 0
            style(row(0..-1), borders: [], text_color: '49442A')
            style(row(0), borders: [:bottom])
            style(columns(2), align: :right)
            style(columns(1), align: :right)
          end
        end
      end

      if @organization.billings.of_period(@period).size > 0
        data = [['<b>Autres</b>', '']]

        @organization.billings.of_period(@period).each do |billing|
          data << ["#{billing.title}", "#{CustomUtils.format_price(billing.price)} €"]

          @total_data_test += CustomUtils.format_price(billing.price).to_f
        end

        data << ['', '']

        @pdf.table(data, width: 540, cell_style: { size: 8, inline_format: true, :padding => [5, 1, 1, 1] }) do
          @pdf.default_leading 0
          style(row(0..-1), borders: [], text_color: '49442A')
          style(row(0), borders: [:bottom])
          style(row(-1), borders: [:bottom])
          style(columns(2), align: :right)
          style(columns(1), align: :right)
        end
      end
    end

    def make_footer
      total = @total_customers_price + @organization.total_billing_of(@period)
      total_data_test = @total_data_test * 100
      vat_text    = '0%'
      total_w_vat = total

      if @invoice.organization.subject_to_vat
        vat_text    = '20%'
        total_w_vat = total * @invoice.vat_ratio
      end

      @pdf.move_down 7
      @pdf.float do
        # ##### TOTAL TEST ######
        # @pdf.text_box 'Total TEST', at: [400, @pdf.cursor], width: 60, align: :right, style: :bold
        # @pdf.move_down 15
        # ##### TOTAL TEST ######
        @pdf.text_box 'Total HT', at: [400, @pdf.cursor], width: 60, align: :right, style: :bold
      end
      # ##### TOTAL TEST ######
      # @pdf.text_box CustomUtils.format_price(total_data_test) + " €", at: [470, @pdf.cursor], width: 66, align: :right
      # @pdf.move_down 15
      # ##### TOTAL TEST ######
      @pdf.text_box CustomUtils.format_price(total) + " €", at: [470, @pdf.cursor], width: 66, align: :right
      @pdf.move_down 10
      @pdf.stroke_horizontal_line 470, 540, at: @pdf.cursor

      @pdf.move_down 7
      @pdf.float do
        @pdf.text_box "TVA (#{vat_text})", at: [400, @pdf.cursor], width: 60, align: :right, style: :bold
      end

      @pdf.text_box CustomUtils.format_price(total_w_vat - total) + " €", at: [470, @pdf.cursor], width: 66, align: :right
      @pdf.move_down 10
      @pdf.stroke_horizontal_line 470, 540, at: @pdf.cursor

      @pdf.move_down 7
      @pdf.float do
        @pdf.text_box 'Total TTC', at: [400, @pdf.cursor], width: 60, align: :right, style: :bold
      end

      @pdf.text_box CustomUtils.format_price(total_w_vat) + " €", at: [470, @pdf.cursor], width: 66, align: :right
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

    def get_human_name_of(package)
      BillingMod::Configuration::LISTS[package.to_sym][:human_name]
    end

    def get_price_of(package)
      BillingMod::Configuration::LISTS[package.to_sym][:price]
    end
  end
end