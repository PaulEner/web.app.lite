class PonctualScripts::NotBilledUsers < PonctualScripts::PonctualScript
  class << self
    def execute
      new().run
    end
  end

  private

  def execute
    period   = 202205

    packages = BillingMod::Package.of_period(period).pluck(:user_id).uniq

    datas = [['Dossier', 'Date Création', 'Date Cloture', 'Nombre de flux avant Mai', 'Nombre de flux après Mai', 'Facture']]

    User.where(id: packages).each do |user|
      billings = user.billings.of_period(period).count
      next if billings > 0 && user.total_billing_of(period).to_f > 0

      preseizures_last = Pack::Report::Preseizure.where('DATE_FORMAT(created_at, "%Y%m") <= ?', period).where(user_id: user.id).count
      preseizures_last = Pack::Piece.where('DATE_FORMAT(created_at, "%Y%m") <= ?', period).where(user_id: user.id).count if preseizures_last == 0

      preseizures_current = Pack::Report::Preseizure.where('DATE_FORMAT(created_at, "%Y%m") > ?', period).where(user_id: user.id).count
      preseizures_current = Pack::Piece.where('DATE_FORMAT(created_at, "%Y%m") > ?', period).where(user_id: user.id).count if preseizures_current == 0

      datas << [user.code, user.created_at, user.inactive_at, preseizures_last, preseizures_current, "#{billings} | #{user.total_billing_of(period).to_f}"]
    end

    send_mail_for(datas)
  end

  private

  def send_mail_for(datas)
    lines = []
    datas.each do |data|
      lines << data.join(';')
    end

    CustomUtils.mktmpdir('export_not_billed', nil, false) do |dir|
      file_path = File.join(dir, "export_not_billed_users.csv")

      File.write(file_path, lines.join("\n"));

      log_document = {
        subject: "[ExportNotBilled] Export Client non facturé",
        name: "ExportNotBilled",
        error_group: "[ExportNotBilled] Export Client non facturé",
        erreur_type: "[ExportNotBilled] - Export Client non facturé",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S')
      }

      begin
        ErrorScriptMailer.error_notification(log_document, { attachements: [{name: "export_not_billed_users.csv", file: File.read(file_path)}]} ).deliver
      rescue
        ErrorScriptMailer.error_notification(log_document).deliver
      end

      p file_path
    end
  end
end