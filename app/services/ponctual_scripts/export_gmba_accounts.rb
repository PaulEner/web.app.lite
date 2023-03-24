class PonctualScripts::ExportGmbaAccounts < PonctualScripts::PonctualScript
  class << self
    def execute
      new().run
    end
  end

  private

  def execute
    date_range = ['2022-07-01 00:00:00', '2022-07-31 23:59:59']

    datas = []

    header = ['Dossier', 'Compte anomalie', "Compte d'attente", "Compte par défaut", "Compte normale"]

    datas << header

    gmba = Organization.find_by_code 'GMBA'
    customers = gmba.customers.active_at(Time.now)

    logger_infos "[ExportGMBA] - Customers size #{customers.size}"

    customers.each_with_index do |customer, index|
      logger_infos "[ExportGMBA] - Parsing ... : #{customer.code} - #{customers.size - index}"

      journals         = customer.account_book_types.select(:anomaly_account, :account_number, :default_account_number)
      anomaly_accounts = []
      waiting_accounts = []
      default_accounts = []
      journals.each do |journal|
        anomaly_accounts << journal.anomaly_account        if journal.anomaly_account.present?
        waiting_accounts << journal.account_number         if journal.account_number.present?
        default_accounts << journal.default_account_number if journal.default_account_number.present?
      end

      preseizures_ids  = customer.preseizures.where("created_at BETWEEN '#{date_range.join("' AND '")}'").select(:id)

      anomaly_accounts_size = 0
      waiting_accounts_size = 0
      default_accounts_size = 0
      all_accounts          = Pack::Report::Preseizure::Account.where(preseizure_id: preseizures_ids).select(:number)

      all_accounts.each do |account|
        if anomaly_accounts.include?(account.number)
          anomaly_accounts_size += 1
        elsif waiting_accounts.include?(account.number)
          waiting_accounts_size += 1
        elsif default_accounts.include?(account.number)
          default_accounts_size += 1
        end
      end


      all_account_size      = all_accounts.size
      normal_accounts_size  = all_account_size - anomaly_accounts_size - waiting_accounts_size - default_accounts_size

      if all_account_size > 0
        datas <<  [  
                    customer.code,
                    "#{anomaly_accounts_size} (#{((anomaly_accounts_size * 100) / all_account_size).to_f.round}%)",
                    "#{waiting_accounts_size} (#{((waiting_accounts_size * 100) / all_account_size).to_f.round}%)",
                    "#{default_accounts_size} (#{((default_accounts_size * 100) / all_account_size).to_f.round}%)",
                    "#{normal_accounts_size} (#{((normal_accounts_size * 100) / all_account_size).to_f.round}%)",
                  ]
      else
        datas <<  [  
                    customer.code,
                    "0 (0%)",
                    "0 (0%)",
                    "0 (0%)",
                    "0 (0%)",
                  ]
      end
    end

    send_mail_for datas

    logger_infos "[ExportGMBA] - All done"
  end

  private

  def send_mail_for(datas)
    lines = []
    datas.each do |data|
      lines << data.join(';')
    end

    CustomUtils.mktmpdir('export_subscription', nil, false) do |dir|
      file_path = File.join(dir, "export_gmba_accounts_juillet.csv")

      File.write(file_path, lines.join("\n"));

      log_document = {
        subject: "[ExportGMBA] Exportation GMBA",
        name: "ExportGMBA",
        error_group: "[ExportGMBA] Exportation GMBA",
        erreur_type: "[ExportGMBA] - Exportation GMBA",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S')
      }

      begin
        ErrorScriptMailer.error_notification(log_document, { attachements: [{name: "export_gmba_accounts_juillet.csv", file: File.read(file_path)}]} ).deliver
      rescue
        ErrorScriptMailer.error_notification(log_document).deliver
      end

      p file_path
    end
  end
end