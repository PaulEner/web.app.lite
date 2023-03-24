class PonctualScripts::ExportSubscriptionNano
  class << self
    def execute
      new().execute
    end
  end

  def execute
    data_each_customer = []
    data_each_customer << ["Organisation", "Code client ", "Actif ?", "Janvier", "Février", "Mars", "Avril", "Mai", "Juin", "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"]
    Organization.billed.each do |organization|
      organization.customers.each do |customer|
        subscription = customer.subscription

        if !subscription.try(:current_packages).nil? && subscription.current_packages.include?('ido_nano')
          data = {}

          subscription.periods.where("periods.current_packages LIKE '%ido_nano%' AND DATE_FORMAT(periods.created_at, '%Y') = 2021 ").order(created_at: :asc).each do |period|
            piece_depassement     = period.excess_compta_pieces
            montant_depassement   = piece_depassement.to_f * 0.25
            piece_total           = period.pieces
            montant_facture       = (5 + montant_depassement).to_s + ' €'
            period_index          = period.created_at.strftime('%m')

            data[period_index] = "Montant : #{montant_facture} | Montant dépassement: #{montant_depassement} € | Pièce total : #{piece_total} | Pièce dépassement : #{piece_depassement}"
          end

          data_each_customer << [ organization.name, customer.code, customer.still_active? ] + %w(01 02 03 04 05 06 07 08 09 10 11 12).map { |per| data[per].presence || '' }
        end
      end
    end

    send_mail_for data_each_customer
  end

  private

  def send_mail_for(datas)
    lines = []
    datas.each do |data|
      lines << data.join(';')
    end

    CustomUtils.mktmpdir('export_subscription', nil, false) do |dir|
      file_path = File.join(dir, "export_subscription_ido_nano.csv")

      File.write(file_path, lines.join("\n"));

      log_document = {
        subject: "[ExportSubscriptionNano] Exportation iDo Nano",
        name: "ExportSubscriptionNano",
        error_group: "[ExportSubscriptionNano] Exportation iDo Nano",
        erreur_type: "[ExportSubscriptionNano] - Exportation iDo Nano",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S')
      }

      begin
        ErrorScriptMailer.error_notification(log_document, { attachements: [{name: "export_subscription_ido_nano.csv", file: File.read(file_path)}]} ).deliver
      rescue
        ErrorScriptMailer.error_notification(log_document).deliver
      end

      p file_path
    end
  end
end