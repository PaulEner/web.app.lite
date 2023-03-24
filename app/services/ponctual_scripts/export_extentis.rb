class PonctualScripts::ExportExtentisCsv < PonctualScripts::PonctualScript
  class << self
    def execute
      new().run
    end
  end

  private

  def execute    
    datas   = []
    periods = []
    header  = ['Dossier']
    
    data_organization = []
    data_old_amount   = []
    data_new_amount   = []

    total_customers_price_old = {}
    total_customers_price     = {}

    13.downto(0) do |i|
      period = i.month.ago.strftime('%Y%m').to_i
      periods << period

      total_customers_price_old[period] = 0
      total_customers_price[period]     = 0

      header << i.month.ago.strftime('%b%Y')
    end

    datas << header

    organization  = Organization.find_by_code 'EXT'
    customers     = organization.customers

    logger_infos "[ExportExt] - Customers size #{customers.size}"

    customers.each_with_index do |customer, index|
      data = []
      periods.each do |period|
        next if not customer.active_at?(period)

        saved_package = customer.package_of period

        period_package = customer.package_simulations.of_period(period).first

        if not period_package
          period_package                      = BillingMod::PackageSimulation.new
          period_package.name                 = 'ido_nano'
          period_package.period               = period
          period_package.mail_active          = saved_package.try(:mail_active)
          period_package.bank_active          = saved_package.try(:bank_active)
          period_package.scan_active          = true
          period_package.preassignment_active = true
          period_package.user                 = customer

          period_package.save
        end

        BillingMod::PrepareUserBilling.new(customer, period, true).execute

        customer.deactivate_simulation
        total_customers_price_old[period] += CustomUtils.format_price(customer.total_billing_of(period)).to_f

        customer.activate_simulation
        total_billing_customer_period  = CustomUtils.format_price(customer.total_billing_of(period)).to_f
        total_customers_price[period] += total_billing_customer_period

        data << total_billing_customer_period
      end

      datas << [customer.code] + data
    end

    periods.each do |period|
      BillingMod::PrepareOrganizationBilling.new(organization, period, true).execute

      organization.deactivate_simulation
      data_old_amount  << total_customers_price_old[period] + CustomUtils.format_price(organization.total_billing_of(period)).to_f

      organization.activate_simulation
      total_organization_price_new = CustomUtils.format_price(organization.total_billing_of(period)).to_f

      data_organization << total_organization_price_new
      data_new_amount  << total_customers_price[period] + total_organization_price_new
    end

    datas << ["Autres"] + data_organization
    datas << ["Nouvelle facture (Nano)"] + data_new_amount
    datas << ["Ancienne facture"] + data_old_amount

    send_mail_for datas

    logger_infos "[ExportExt] - All done"
  end

  private

  def send_mail_for(datas)
    lines = []
    datas.each do |data|
      lines << data.join(';')
    end

    CustomUtils.mktmpdir('export_ext', nil, false) do |dir|
      file_path = File.join(dir, "export_ext.csv")

      File.write(file_path, lines.join("\n"));

      log_document = {
        subject: "[ExportExt] Exportation Ext",
        name: "ExportExtExportExt",
        error_group: "[ExportExt] Exportation Ext",
        erreur_type: "[ExportExt] - Exportation Ext",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S')
      }

      begin
        ErrorScriptMailer.error_notification(log_document, { attachements: [{name: "export_extentis.csv", file: File.read(file_path)}]} ).deliver
      rescue
        ErrorScriptMailer.error_notification(log_document).deliver
      end

      p file_path
    end
  end
end